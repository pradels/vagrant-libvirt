require 'log4r'

module VagrantPlugins
  module ProviderLibvirt
    module Action
      class HandleBoxImage

        @@lock = Mutex.new

        def initialize(app, env)
          @logger = Log4r::Logger.new('vagrant_libvirt::action::handle_box_image')
          @app = app
        end

        def call(env)

          # Verify box metadata for mandatory values.
          #
          # Virtual size has to be set for allocating space in storage pool.
          box_virtual_size = env[:machine].box.metadata['virtual_size']
          if box_virtual_size == nil
            raise Errors::NoBoxVirtualSizeSet
          end

          # Support qcow2 format only for now, but other formats with backing
          # store capability should be usable.
          box_format = env[:machine].box.metadata['format']
          if box_format == nil
            raise Errors::NoBoxFormatSet
          elsif box_format != 'qcow2'
            raise Errors::WrongBoxFormatSet
          end

          # Get config options
          config   = env[:machine].provider_config
          box_image_file = env[:machine].box.directory.join('box.img').to_s
          env[:box_volume_name] = env[:machine].box.name.to_s.dup.gsub("/", "-VAGRANTSLASH-")
          env[:box_volume_name] << '_vagrant_box_image.img'

          @@lock.synchronize do
            # Don't continue if image already exists in storage pool.
            return @app.call(env) if ProviderLibvirt::Util::Collection.find_matching(
              env[:libvirt_compute].volumes.all, env[:box_volume_name])

            # Box is not available as a storage pool volume. Create and upload
            # it as a copy of local box image.
            env[:ui].info(I18n.t('vagrant_libvirt.uploading_volume'))

            # Create new volume in storage pool
            raise Errors::BoxNotFound if !File.exists(box_image_file)
            box_image_size = File.size(box_image_file) # B
            message = "Creating volume #{env[:box_volume_name]}"
            message << " in storage pool #{config.storage_pool_name}."
            @logger.info(message)
            begin
              fog_volume = env[:libvirt_compute].volumes.create(
                name:         env[:box_volume_name],
                allocation:   "#{box_image_size/1024/1024}M",
                capacity:     "#{box_virtual_size}G",
                format_type:  box_format,
                pool_name:    config.storage_pool_name)
            rescue Fog::Errors::Error => e
              raise Errors::FogCreateVolumeError,
                :error_message => e.message
            end

            # Upload box image to storage pool
            ret = upload_image(box_image_file, config.storage_pool_name,
              env[:box_volume_name], env) do |progress|
                env[:ui].clear_line
                env[:ui].report_progress(progress, box_image_size, false)
            end

            # Clear the line one last time since the progress meter doesn't
            # disappear immediately.
            env[:ui].clear_line

            # If upload failed or was interrupted, remove created volume from
            # storage pool.
            if env[:interrupted] || !ret
              begin
                fog_volume.destroy
              rescue
                nil
              end
            end
          end

          @app.call(env)
        end

        protected

        # Fog libvirt currently doesn't support uploading images to storage
        # pool volumes. Use ruby-libvirt client instead.
        def upload_image(image_file, pool_name, volume_name, env)
          image_size = File.size(image_file) # B

          begin
            pool = env[:libvirt_compute].client.lookup_storage_pool_by_name(
              pool_name)
            volume = pool.lookup_volume_by_name(volume_name)
            stream = env[:libvirt_compute].client.stream
            volume.upload(stream, offset=0, length=image_size)

            # Exception ProviderLibvirt::RetrieveError can be raised if buffer is
            # longer than length accepted by API send function.
            #
            # TODO: How to find out if buffer is too large and what is the
            # length that send function will accept?

            buf_size = 1024*250 # 250K
            progress = 0
            open(image_file, 'rb') do |io|
              while (buff = io.read(buf_size)) do
                sent = stream.send buff
                progress += sent
                yield progress
              end
            end
          rescue => e
            raise Errors::ImageUploadError,
              :error_message => e.message
          end

          if progress == image_size
            return true
          else
            return false
          end
        end

      end
    end
  end
end

