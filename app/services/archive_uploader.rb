class ArchiveUploader
  # Limit of filezise
  FILE_SIZE_LIMIT_FOR_SPLIT = ENV.fetch('ARCHIVE_FILE_SIZE_LIMIT_FOR_CUSTOM_UPLOAD') { 4.gigabytes }
  # Path to https://docs.openstack.org/python-swiftclient/latest/
  UPLOADER_PATH = ENV.fetch('ARCHIVE_CUSTOM_UPLOADER_PATH') { Rails.root.join('swift_wrapper.sh') }

  def upload
    adapter_for(filepath: filepath)
  end

  private

  attr_reader :procedure, :archive, :filepath

  def adapter_for(filepath:)
    case File.size(filepath)
    when 0..FILE_SIZE_LIMIT_FOR_SPLIT then
      upload_with_active_storage
    else
      upload_with_custom_wrapper
    end
  end

  def upload_with_active_storage
    archive.file.attach(
      io: File.open(filepath),
      filename: object_filename,
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
  end

  def upload_with_custom_wrapper
    blob = ActiveStorage::Blob.create_before_direct_upload!(
        key: SecureRandom.uuid,
        filename: object_filename,
        byte_size: File.size(filepath),
        checksum: Digest::SHA256.file(filepath).hexdigest,
        content_type: 'application/zip',
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
    upload_success = system UPLOADER_PATH.to_s, filepath, blob.key
    byebug
    if upload_success
    byebug
      archive.file.purge if archive.file.attached?
      ActiveStorage::Attachment.create(
        name: 'file',
        record_type: 'Archive',
        record_id: archive.id,
        blob_id: blob.id
      )
    byebug
      # archive.file.attach(blob.signed_id)
    else
      # blob.destroy
      fail "should be retried ?"
    end
  end

  def object_filename
    archive.filename(procedure)
  end

  def initialize(procedure:, archive:, filepath:)
    @procedure = procedure
    @archive = archive
    @filepath = filepath
  end
end
