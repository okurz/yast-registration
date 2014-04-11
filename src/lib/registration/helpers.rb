# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2014 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------
#
#

require "yast"
require "uri"

module Registration

  class Helpers
    include Yast::Logger
    extend Yast::I18n

    textdomain "registration"

    Yast.import "Linuxrc"
    Yast.import "Mode"
    Yast.import "Popup"
    Yast.import "Report"
    Yast.import "SlpService"

    # name of the boot parameter
    BOOT_PARAM = "reg_url"

    # SLP service name
    SLP_SERVICE = "registration.suse"

    # Get the language for using in HTTP requests (in "Accept-Language" header)
    def self.language
      lang = Yast::WFM.GetLanguage
      log.info "Current language: #{lang}"

      if lang == "POSIX" || lang == "C"
        log.warn "Ignoring #{lang.inspect} language for HTTP requests"
        return nil
      end

      # remove the encoding (e.g. ".UTF-8")
      lang.sub!(/\..*$/, "")
      # replace lang/country separator "_" -> "-"
      # see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
      lang.tr!("_", "-")

      log.info "Language for HTTP requests set to #{lang.inspect}"
      lang
    end


    # Evaluate the registration URL to use
    # @see https://github.com/yast/yast-registration/wiki/Changing-the-Registration-Server
    # for details
    # @return [String,nil] registration URL, nil means use the default
    def self.registration_url
      # TODO FIXME: handle autoyast mode as well, currently it is handled in scc_auto client
      return reg_url_at_upgrade if Yast::Mode.update
      return reg_url_at_installation if Yast::Mode.installation
      return reg_url_at_runnig_system if Yast::Mode.normal

      log.warn "Unknown mode: #{Mode.mode} using default URL"
      # no custom URL, use the default
      nil
    end

    # convert service URL to plain URL, remove the SLP service prefix
    # "service:registration.suse:smt:https://scc.suse.com/connect" ->
    # "https://scc.suse.com/connect"
    def self.service_url(service)
      service.sub(/\Aservice:#{Regexp.escape(SLP_SERVICE)}:[^:]+:/, "")
    end

    # return "credentials" parameter from URL
    # raises URI::InvalidURIError if URL is invalid
    # @param url [String] URL as string
    def self.credentials_from_url(url)
      parsed_url = URI(url)
      params = Hash[URI.decode_www_form(parsed_url.query)]

      params["credentials"]
    end

    # Create radio button label for a SLP service
    # @param service [Yast::SlpServiceClass::Service] SLP service
    # @return [String] label
    def self.service_description(service)
      url  = service_url(service.slp_url)
      descr = service.attributes.to_h[:description]

      # display URL and the description if it is present
      (descr && !descr.empty?) ? "#{descr} (#{url})" : url
    end

    def self.run_network_configuration
      log.info "Running network configuration..."
      Yast::WFM.call("inst_lan", [{"skip_detection" => true}])
    end


    private

    # get registration URL in installation mode
    def self.reg_url_at_installation
      # boot command line if present
      boot_url = boot_reg_url
      return boot_url if boot_url

      # SLP discovery
      slp_url = slp_service_url
      return slp_url if slp_url

      # use the default
      nil
    end

    # get registration URL in upgrade mode
    def self.reg_url_at_upgrade
      # boot command line if present
      boot_url = boot_reg_url
      return boot_url if boot_url

      # TODO FIXME: read the URL from the old configuration file
      # (old suse_register.conf or old SCC config file)

      # try SLP if not registered
      slp_url = slp_service_url
      return slp_url if slp_url

      # use the default
      nil
    end

    # get registration URL in running system
    def self.reg_url_at_runnig_system
      # TODO FIXME: read the URL from configuration file to use the same URL
      # at re-registration as in installation

      # try SLP if not registered yet
      slp_url = slp_service_url
      return slp_url if slp_url

      # use the default
      nil
    end


    # return the boot command line parameter
    def self.boot_reg_url
      parameters = Yast::Linuxrc.InstallInf("Cmdline")
      return nil unless parameters

      registration_param = parameters.split.grep(/\A#{BOOT_PARAM}=/i).last
      return nil unless registration_param

      reg_url = registration_param.split('=', 2).last
      log.info "Boot reg_url option: #{reg_url.inspect}"

      reg_url
    end

    def self.slp_service_url
      log.info "Starting SLP discovery..."
      url = Yast::WFM.call("discover_registration_services")
      log.info "Selected SLP service: #{url.inspect}"

      url
    end

    def self.slp_discovery
      services = []

      log.info "Searching for #{SLP_SERVICE} SLP services"
      services.concat(Yast::SlpService.all(SLP_SERVICE))

      log.debug "Found services: #{services.inspect}"
      log.info "Found #{services.size} services: #{services.map(&:slp_url).inspect}"

      services
    end

    def self.slp_discovery_feedback
      Yast::Popup.Feedback(_("Searching..."), _("Looking up local registration servers...")) do
        slp_discovery
      end
    end

  end
end