# Class Rest_backend
# Description: Salesforce CMS REST back end to Hiera.
# Author: Ben Ford <ben.ford@puppetlabs.com>
#
class Hiera
  module Backend
    class Rest_backend
      def initialize
        require 'active_support'
        require "net/https"   # use instead of rest-client so we can set SSL options

        # I think this connection can be reused like this. If not, move it to the query and make it local
        @http = Net::HTTP.new(Config[:rest][:server], Config[:rest][:port])
        
        if Config[:rest].has_key?(:cacrt)
          @http.use_ssl = true
          @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  
          store = OpenSSL::X509::Store.new
          store.add_cert(OpenSSL::X509::Certificate.new(File.read(Config[:rest][:cacrt])))
          @http.cert_store = store
  
          @http.key = OpenSSL::PKey::RSA.new(File.read(Config[:rest][:crt]))
          @http.cert = OpenSSL::X509::Certificate.new(File.read(Config[:rest][:crtkey]))
        else
          @http.use_ssl = false
        end

        debug ("Loaded Rest_backend")
      end

      def debug(msg)
        Hiera.debug("[REST]: #{msg}")
      end

      def warn(msg)
        Hiera.warn("[REST]:  #{msg}")
      end

      def lookup(key, scope, order_override, resolution_type)
        debug("Looking up '#{key}', resolution type is #{resolution_type}")
        answer = nil

        Backend.datasources(scope, order_override) do |source|
          debug("Looking for data in #{source}")

          data = restquery(key, source)

          # if we want to support array responses, this will have to be more intelligent
          next unless data.include?(key)
          debug ("Key '#{key}' found in REST response, Passing answer to hiera")

          parsed_answer = Backend.parse_answer(data[key], scope)

          begin
            case resolution_type
            when :array
              debug("Appending answer array")
              raise Exception, "Hiera type mismatch: expected Array and got #{parsed_answer.class}" unless parsed_answer.kind_of? Array or parsed_answer.kind_of? String
              answer ||= []
              answer << parsed_answer
            when :hash
              debug("Merging answer hash")
              raise Exception, "Hiera type mismatch: expected Hash and got #{parsed_answer.class}" unless parsed_answer.kind_of? Hash
              answer ||= {}
              answer = parsed_answer.merge answer
            else
              debug("Assigning answer variable")
              answer = parsed_answer
              break
            end
          rescue NoMethodError
            raise Exception, "Resolution type is #{resolution_type} but parsed_answer is a #{parsed_answer.class}"
          end
        end

        return answer
      end

      # we'll have to encode the search parameters in the hierarchy. For example:
      def restquery(key, source)
        # figure out what query we need
        case source
        when /host\/([^\/]*)$/                          # host/%{hostname}
          query = "Host?name=#{$1}"
        when /pod\/([^\/]*)$/                           # pod/%{pod}
          query = "Pod?name=#{$1}"
        when /superpod\/([^\/]*)\/pod\/([^\/]*)$/       # superpod/%{superpod}/pod/%{pod}
          query = "Superpod?name=#{$1}&Pod?name=#{$2}"
        else
          debug("Got a query we can't handle yet!")
          return {}
        end

        debug("Query: #{Config[:rest][:api]}/#{query}")

        request = Net::HTTP::Get.new("#{Config[:rest][:api]}/#{query}")
        response = ActiveSupport::JSON.decode(@http.request(request).body)

        # do we want to support array responses? It's built in to Hiera; see above
        return response['success'] ? response['data'][0] : {}
      end
    end
  end
end
