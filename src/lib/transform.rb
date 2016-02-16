class Transform

  attr_accessor :env
  attr_accessor :svc
  attr_accessor :table
  attr_accessor :settings
  attr_accessor :config_files
  attr_accessor :debug_mode

  NO_VALUE = 'no'
  ROWKEY = 'RowKey'
  SETTING = 'setting'
  VALUE = 'value'
  APPCLIENTID = 'AppClientId'
  APPIDURI = 'AppIdUri'
  OLDAPPID = 'AppId'
  EMPTY_STR = ''
  STORAGEACCOUNT = 'StorageAccount'
  STORAGEACCOUNTKEY = "#{STORAGEACCOUNT}Key"
  CONNECTIONSTRING = 'connectionString'

  def get(key)
    begin
      result = @svc.get_entity(@table, @env, key)
    rescue
      puts $!
      puts "Error retrieving key: #{@key}"
      puts
    end

    result
  end

  def get_all
    begin
      query = { :filter => "PartitionKey eq '#{@env}'" }
      result = @svc.query_entities(@table, query)
    rescue
      puts $!
      puts "Error retrieving table entities for Env : #{@env}"
      puts
    end

    result
  end

  def get_value(key)
    if (@settings.nil?)
      return
    end
    value = EMPTY_STR
    @settings.each { |i|
      if i.properties[ROWKEY] == key
        value = i.properties[SETTING]
        break
      end
    }

    value
  end

  def transform_appsettings(key = EMPTY_STR, value = EMPTY_STR)
    # go to each file and replace value of matching appSettings key
    @config_files.each{|file|
      doc = Nokogiri::XML(File.read(file))
      puts "Processing file: #{file}"
      if (key.to_s != EMPTY_STR && value.to_s != EMPTY_STR)
        k = key
        v = value
        status = update_appsetting(k, v, doc, file)
        if status == :updated
          if (@debug_mode)
            puts "Updated key #{k} with #{v}"
          else
            puts "Updated key: #{k}"
          end
        end
      else
        if (!@settings.nil?)
          @settings.each { |i|
            k = i.properties[ROWKEY] || NO_VALUE
            v = i.properties[SETTING] || NO_VALUE
            status = update_appsetting(k, v, doc, file)
            if status == :updated
              if (@debug_mode)
                puts "Updated key #{k} with #{v}"
              else
                puts "Updated key: #{k}"
              end
            end
          }
        end
      end
    }
  end

  def update_appsetting(k, v, doc, file)
    status = :noargs
    if (k != NO_VALUE && v != NO_VALUE)
      node = doc.at_css "appSettings/add[@key='#{k}']"
      if !node.nil?
        puts "Old value: #{node[VALUE]}" if @debug_mode
        node[VALUE] = v
        puts "New value: #{v}" if @debug_mode
        File.write(file, doc.to_xml)
        status = :updated
      else
        status = :notfound
      end
    end

    status
  end

  def transform_servicemodelconfig
    @config_files.each{|file|
      doc = Nokogiri::XML(File.read(file))
      doc.xpath('//system.serviceModel').each do |node|
        if !node.nil?
          if file.end_with?('app.config') || file.end_with?('App.config')
            val = get_value('system.ServiceModel.Client')
            node.replace(val) if (!val.nil?)
          elsif file.end_with?('Web.config')
            val = get_value('system.ServiceModel.Service')
            node.replace(val) if (!val.nil?)
          end
          File.write(file, doc.to_xml)
        end
      end
    }
  end

  def transform_systemwebcompilationattribs
    @config_files.each{|file|
      doc = Nokogiri::XML(File.read(file))
      node = doc.at_css 'compilation'
      if !node.nil?
        #puts node
        node.xpath('//@debug').remove
        node.xpath('//@tempDirectory').remove
        #puts node
        File.write(file, doc.to_xml)
      end
    }
  end

  def transform_csdef
    csdef = Dir.glob('**/*.csdef')
    csdef.each{ |file|
      doc = Nokogiri::XML(File.read(file))

      node = doc.at_css 'ServiceDefinition'
      node['name'] = @service_name if !node.nil?

      node = doc.at_css 'WebRole'
      node['name'] = @service_name if !node.nil?

      node = doc.at_css 'WorkerRole'
      node['name'] = @service_name if !node.nil?

      node = doc.at_css 'Certificates'
      node.replace(get_value('Certificates_csdef')) if !node.nil?

      node = doc.at_css 'Endpoints'
      node.replace(get_value('Endpoints')) if !node.nil?

      node = doc.at_css 'Bindings'
      node.replace(get_value('Bindings')) if !node.nil?

      node = doc.at_css 'Sites'
      node.replace(get_value('Sites')) if !node.nil?

      node = doc.at_css 'Imports'
      node.replace(get_value('Imports')) if !node.nil?

      node = doc.at_css 'LocalResources'
      node.replace(get_value('LocalResources')) if !node.nil?

      File.write(file, doc.to_xml)
    }
  end

  def transform_cscfg
    csdef = Dir.glob('**/*.cscfg')
    csdef.each{ |file|
      doc = Nokogiri::XML(File.read(file))

      node = doc.at_css 'ServiceConfiguration'
      node['serviceName'] = @service_name if !node.nil?

      node = doc.at_css 'Role'
      node['name'] = @service_name if !node.nil?

      node = doc.at_css 'Certificates'
      node.replace(get_value('Certificates_cscfg')) if !node.nil?

      node = doc.at_css 'ConfigurationSettings'
      node.replace(get_value('ConfigurationSettings_cscfg')) if !node.nil?

      File.write(file, doc.to_xml)
    }
  end

  def transform_appinsights(paths_to_exclude)
    aiconfig = Dir.glob('**/ApplicationInsights.config')

    remove_paths_from_list(paths_to_exclude, aiconfig)

    aiconfig.each{ |file|
      doc = Nokogiri::XML(File.read(file))

      node = doc.at_css 'InstrumentationKey'
      if (!node.nil?)
        val_from_settings = get_value('AI_InstrumentationKey')
        if (val_from_settings.to_s == EMPTY_STR)
          aikey =  ENV['AI_InstrumentationKey'] || NO_VALUE
        else
          aikey = val_from_settings
        end
        if (aikey != NO_VALUE)
          node.content = aikey
        end
      end

      File.write(file, doc.to_xml)
    }
  end

  def transform_diagnosticscfg
    csdef = Dir.glob('**/*.wadcfgx')
    csdef.each{ |file|
      doc = Nokogiri::XML(File.read(file))

      node = doc.at_css "PrivateConfig/#{STORAGEACCOUNT}"
      node['name'] = get_value(STORAGEACCOUNT)
      node['key'] = get_value(STORAGEACCOUNTKEY)
      node = doc.at_css STORAGEACCOUNT
      node.content = get_value(STORAGEACCOUNT)

      File.write(file, doc.to_xml)
    }
  end

  def transform_cacheclient
    cacheclient_id = get_value('CacheClient_Identifier')
    @config_files.each{ |file|
      doc = Nokogiri::XML(File.read(file))

      node = doc.at_css 'dataCacheClients/dataCacheClient/autoDiscover'
      if (!node.nil?)
        node['identifier'] = cacheclient_id
      end

      File.write(file, doc.to_xml)
    }
  end

  # log level and azure table appender parameters are transformed
  def transform_log4net
    config_files = Dir.glob('**/log4net.config')
    config_files.each{ |file|
      doc = Nokogiri::XML(File.read(file))

      # azure table name is service name
      node = doc.at_css 'log4net/appender[@name=AzureTableAppender]/param[@name=TableName]'
      node['value'] = @service_name if (!node.nil?)

      node = doc.at_css 'log4net/appender[@name=AzureTableAppender]/param[@name=ConnectionString]'
      log_connstr = ENV["log#{CONNECTIONSTRING}"] || NO_VALUE
      if log_connstr == NO_VALUE
        puts "No logging #{CONNECTIONSTRING} found."
      else
        node['value'] = log_connstr if (!node.nil?)
      end

      # log level
      node = doc.at_css 'log4net/root/level'
      node['value'] = ENV['loglevel'] if (!node.nil?)

      File.write(file, doc.to_xml)
    }
  end

  def remove_paths_from_list(paths_to_exclude, source_list)
    paths_to_exclude.each { |path|
      source_list.delete_if { |file|
        file.include?(path)
      }
    }
  end

  # paths_to_exclude is array of partial or full paths of projects where transform needs skipped
  def transform(paths_to_exclude = [])

    @debug_mode = ENV['transform_debug_mode']

    # --- Get environment invoked
    @env = ENV['env'] || NO_VALUE
    if @env == NO_VALUE
      puts 'Environment name required to transform. No configuration changes will be done...'
      return false
    else
      puts "Transforming config for environment: #{@env} ..."
    end

    # --- Get Settings Account Name, Key and Table from Environment variables
    settings_account_name = ENV['SettingsAccount'] || ENV[STORAGEACCOUNT] || NO_VALUE
    if (settings_account_name == NO_VALUE)
      puts "No settings storage account name found"
      return false
    end
    settings_access_key = ENV['SettingsAccountKey'] || ENV[STORAGEACCOUNTKEY] || NO_VALUE
    if (settings_access_key == NO_VALUE)
      puts "No settings storage account key found"
      return false
    end
    config_table = ENV['ConfigSettingsTable'] || NO_VALUE
    if (config_table == NO_VALUE)
      puts "No configuration table found"
    end

    # --- Collect config files to transform
    # find all App.config and web.config files
    @config_files = Dir.glob('**/app.config')
    @config_files.concat(Dir.glob('**/appSettings.config'))
    @config_files.concat(Dir.glob('**/web.config'))
    @config_files.concat(Dir.glob('**/RuntimeWeb/*Web.dll.config'))
    @config_files.concat(Dir.glob('**/RuntimeService/*.exe.config'))

    # remove projects which need not be transformed
    remove_paths_from_list(paths_to_exclude, @config_files)

    # --- Load Settings from storage
    # azure table storage account where settings reside
    Azure.config.storage_account_name = settings_account_name
    Azure.config.storage_access_key = settings_access_key
    @table = config_table

    # table service
    @svc = Azure::TableService.new

    # get all settings for environment
    @settings = get_all

    # --- Start Transformations ---
    puts "updating settings #{CONNECTIONSTRING}..."
    settings_connstr = "DefaultEndpointsProtocol=https;AccountName=#{settings_account_name};AccountKey=#{settings_access_key}"
    should_update_settings_connstr = ENV['should_update_settings_connstr'] || NO_VALUE
    if should_update_settings_connstr == NO_VALUE
      puts "Flag for Setttings #{CONNECTIONSTRING} Update not set."
    else
      transform_appsettings(CONNECTIONSTRING, settings_connstr)
    end

    puts "updating unit test #{CONNECTIONSTRING}..."
    unitest_connstr = ENV["unitest#{CONNECTIONSTRING}"] || NO_VALUE
    if unitest_connstr == NO_VALUE
      puts "No unit test #{CONNECTIONSTRING} found."
    else
      transform_appsettings("unitest#{CONNECTIONSTRING}", unitest_connstr)
    end

    puts "updating #{APPCLIENTID}..."
    appClientId = ENV[APPCLIENTID] || NO_VALUE
    if appClientId == NO_VALUE
      puts "No #{APPCLIENTID} found."
      # old version notify check
      oldAppId = ENV[OLDAPPID]
      if oldAppId != NO_VALUE
        puts "You appear to be using the old AppId environment variable, AppClientId is expected. Proceeding with old AppId update."
        transform_appsettings(OLDAPPID, oldAppId)
      end
    else
      transform_appsettings(APPCLIENTID, appClientId)
    end

    puts "updating #{APPIDURI}..."
    appIdUri = ENV[APPIDURI] || NO_VALUE
    if appIdUri == NO_VALUE
      puts "No #{APPIDURI} found."
    else
      transform_appsettings(APPIDURI, appIdUri)
    end

    @service_name = ENV['ServiceName']
    is_service = @service_name || NO_VALUE
    if is_service != NO_VALUE
      puts "Transforming config for service: #{@service_name}"

      puts 'Obtaining cloud configuration templates...'
      csdefTemplate = get_value('ServiceDefinitionTemplate')
      File.write('ServiceDefinition.csdef', csdefTemplate)
      cscfgTemplate = get_value('ServiceConfigurationTemplate')
      File.write('ServiceConfiguration.cscfg', cscfgTemplate)

      puts 'Transforming csdef...'
      transform_csdef

      puts 'Transforming cscfg...'
      transform_cscfg

      puts 'Transforming diagnostics cfg...'
      transform_diagnosticscfg

      puts 'Replacing service model settings...'
      transform_servicemodelconfig
    else
      puts 'Target to transform is not a service...'
    end

    puts 'Replacing app settings...'
    transform_appsettings

    puts 'Removing debug compilation attributes...'
    transform_systemwebcompilationattribs

    puts 'Transforming cache client...'
    transform_cacheclient

    puts 'Transforming Application Insights...'
    transform_appinsights(paths_to_exclude)

    puts 'Transforming log4net config...'
    transform_log4net

    return true
  end

end
