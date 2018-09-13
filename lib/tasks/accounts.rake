# frozen_string_literal: true

namespace :accounts do
  desc "Perform migration"
  task :migration, %i[archive_path new_user_name] => :environment do |_t, args|
    puts "Account migration is requested"
    process_arguments(args)

    begin
      service = MigrationService.new(args[:archive_path], args[:new_user_name])
      service.validate_archive
      puts "Warnings:\n#{service.warnings}\n-----" if service.warnings.any?
      # TODO: ask for confirmation
      start_time = Time.now.getlocal
      service.perform!
      puts "Complete!"
      puts "Migration took #{Time.now.getlocal - start_time} seconds"
    rescue MigrationService::ArchiveValidationFailed => exception
      puts "Errors in the archive found:\n#{exception.message}\n-----"
    end
  end

  def process_arguments(args)
    # TODO: ask arguments interactively if not provided
    puts "Archive path: #{args[:archive_path]}"
    puts "New username: #{args[:new_user_name]}"
  end
end
