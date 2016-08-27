require 'yaml'
require 'erb'
require 'uri'
require 'base64'

module Happo
  class Utils
    def self.config
      @@config ||= {
        'snapshots_folder' => './snapshots',
        'source_files' => [],
        'stylesheets' => [],
        'public_directories' => [],
        'port' => 4567,
        'driver' => :firefox,
        'viewports' => {
          'large' => {
            'width' => 1024,
            'height' => 768
          },
          'medium' => {
            'width' => 640,
            'height' => 888
          },
          'small' => {
            'width' => 320,
            'height' => 444
          }
        }
      }.merge(config_from_file)
    end

    def self.config_from_file
      config_file_name = ENV['HAPPO_CONFIG_FILE'] || '.happo.yaml'
      if File.exist?(config_file_name)
        YAML.load(ERB.new(File.read(config_file_name)).result)
      else
        {}
      end
    end

    def self.normalize_description(description)
      Base64.strict_encode64(description).strip
    end

    def self.path_to(description, viewport_name, file_name)
      File.join(
        config['snapshots_folder'],
        normalize_description(description),
        "@#{viewport_name}",
        file_name
      )
    end

    def self.construct_url(absolute_path, params = {})
      query = URI.encode_www_form(params) unless params.empty?

      URI::HTTP.build(host: 'localhost',
                      port: config['port'],
                      path: absolute_path,
                      query: query).to_s
    end

    def self.pluralize(count, singular, plural)
      if count == 1
        "#{count} #{singular}"
      else
        "#{count} #{plural}"
      end
    end

    def self.page_title(diff_images, new_images)
      title = []

      unless diff_images.count == 0
        title << pluralize(diff_images.count, 'diff', 'diffs')
      end

      title << "#{new_images.count} new" unless new_images.count == 0

      "#{title.join(', ')} · Happo"
    end

    def self.favicon_as_base64
      favicon = File.expand_path('../public/favicon.ico', __FILE__)
      "data:image/ico;base64,#{Base64.encode64(File.binread(favicon))}"
    end

    def self.css_styles
      File.read(File.expand_path('../public/happo-styles.css', __FILE__))
    end

    def self.last_result_summary
      YAML.load(File.read(File.join(
        self.config['snapshots_folder'], 'result_summary.yaml')))
    end

    def self.to_slug(string)
      value = string.gsub(/[^\x00-\x7F]/n, '').to_s
      value.gsub!(/[']+/, '')
      value.gsub!(/\W+/, ' ')
      value.strip!
      value.downcase!
      value.tr!(' ', '-')
      value
    end

    def self.image_slug(diff_image)
      to_slug("#{diff_image[:description]} #{diff_image[:viewport]}")
    end
  end
end
