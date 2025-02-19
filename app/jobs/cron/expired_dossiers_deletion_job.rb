class Cron::ExpiredDossiersDeletionJob < Cron::CronJob
  self.schedule_expression = "every day at 7 am"

  def perform(*args)
    ExpiredDossiersDeletionService.process_expired_dossiers_brouillon
    ExpiredDossiersDeletionService.process_expired_dossiers_en_construction
    ExpiredDossiersDeletionService.process_expired_dossiers_termine
  end
end
