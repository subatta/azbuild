class Update

  attr_accessor :dry_run
  attr_accessor :env
  attr_accessor :settings
  attr_accessor :svc
  attr_accessor :table

  def initialize(env, settings, dry_run = nil)
    @env = env || 'noenv'
    @settings = settings
    @dry_run = dry_run
  end

  def update
    if @env == 'noenv'
      puts 'Environment name required to update settings.'
      return false
    end

    # error thrown by azure gem if these are bad
    Azure.config.storage_account_name = ENV['StorageAccount']
    Azure.config.storage_access_key = ENV['StorageAccountKey']
    @table = ENV['ConfigSettingsTable']

    puts
    puts 'Updating config table...'
    puts

    @svc = create_table_if_not_exists

    upsert_all(@settings)
  end

  def create_table_if_not_exists
    azure_table_service = Azure::TableService.new
    begin
      azure_table_service.create_table(@table)
    rescue
      puts $!
      puts "table : #{@table}"
      puts
    end
    azure_table_service
  end

  def upsert_all(settings)
    settings.map {|k,v|
      upsert(k, v)
      #echo(k)
    }
  end

  def upsert(key, value)

    # check if setting exists
    result = get(key)

    entity = {
      "setting" => value,
      :PartitionKey => @env,
      :RowKey => key
    }

    if (result.nil?)
      @svc.insert_entity(@table, entity) if @dry_run.nil?
      puts ">>>>> inserted entity key: #{key} value: #{value}"
    else
      # don't reinsert same value
      if (result.properties['setting'] != value)
        @svc.delete_entity(@table, @env, key) if @dry_run.nil?
        @svc.insert_entity(@table, entity) if @dry_run.nil?
        puts ">>>>> Updated entity - key: #{key} value: #{value}"
      else
        puts "Same value: #{value} found for key: #{key}" if @dry_run.nil?
      end
    end

  end

  def get(key)

    begin
      result = @svc.get_entity(@table, @env, key)
    rescue
      puts $!
      puts "key : #{key}"
      puts
    end

    result
  end

  def echo(key)
    entity = get(key)
    if !entity.nil?
      puts "echo: "
      p entity.properties
    end
  end
end
