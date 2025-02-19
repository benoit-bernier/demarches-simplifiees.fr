RSpec.describe DossierMailer, type: :mailer do
  let(:to_email) { 'instructeur@exemple.gouv.fr' }

  shared_examples 'a dossier notification' do
    it 'is sent from a no-reply address' do
      expect(subject.from.first).to eq(Mail::Address.new(NO_REPLY_EMAIL).address)
    end

    it 'includes the contact informations in the footer' do
      expect(subject.body).to include('ne pas répondre')
    end
  end

  describe '.notify_new_draft' do
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure, :with_auto_archive)) }

    subject { described_class.notify_new_draft(dossier) }

    it { expect(subject.subject).to include("brouillon") }
    it { expect(subject.subject).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include(dossier_url(dossier)) }
    it { expect(subject.body).to include("Vous pouvez déposer votre dossier jusqu’au") }
    it { expect(subject.body).to include("heure de") }

    it_behaves_like 'a dossier notification'
  end

  describe '.notify_new_answer with dossier brouillon' do
    let(:service) { build(:service) }
    let(:procedure) { create(:simple_procedure, service: service) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:commentaire) { create(:commentaire, dossier: dossier) }
    subject { described_class.with(commentaire: commentaire).notify_new_answer }

    it { expect(subject.subject).to include("Nouveau message") }
    it { expect(subject.subject).to include(dossier.id.to_s) }
    it { expect(subject.body).to include(dossier.procedure.service.email) }
    it { expect(subject.body).not_to include(messagerie_dossier_url(dossier)) }

    it_behaves_like 'a dossier notification'

    context 'when there is no associated service' do
      let(:service) { nil }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '.notify_new_answer with dossier en construction' do
    let(:dossier) { create(:dossier, :en_construction, procedure: create(:simple_procedure)) }
    let(:commentaire) { create(:commentaire, dossier: dossier) }

    subject { described_class.with(commentaire: commentaire).notify_new_answer }

    it { expect(subject.subject).to include("Nouveau message") }
    it { expect(subject.subject).to include(dossier.id.to_s) }
    it { expect(subject.body).to include(messagerie_dossier_url(dossier)) }

    it_behaves_like 'a dossier notification'
  end

  describe '.notify_new_answer with commentaire discarded' do
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure)) }
    let(:commentaire) { create(:commentaire, dossier: dossier, discarded_at: 2.minutes.ago) }

    subject { described_class.with(commentaire: commentaire).notify_new_answer }

    it { expect(subject.perform_deliveries).to be_falsy }
  end

  def notify_deletion_to_administration(deleted_dossier, to_email)
    @subject = default_i18n_subject(dossier_id: deleted_dossier.dossier_id)
    @deleted_dossier = deleted_dossier

    mail(to: to_email, subject: @subject)
  end

  describe '.notify_deletion_to_administration' do
    let(:deleted_dossier) { build(:deleted_dossier) }

    subject { described_class.notify_deletion_to_administration(deleted_dossier, to_email) }

    it { expect(subject.subject).to eq("Le dossier nº #{deleted_dossier.dossier_id} a été supprimé à la demande de l’usager") }
    it { expect(subject.body).to include("À la demande de l’usager") }
    it { expect(subject.body).to include(deleted_dossier.dossier_id) }
    it { expect(subject.body).to include(deleted_dossier.procedure.libelle) }
  end

  describe '.notify_revert_to_instruction' do
    let(:dossier) { create(:dossier, procedure: create(:simple_procedure)) }

    subject { described_class.notify_revert_to_instruction(dossier) }

    it { expect(subject.subject).to include('réexaminé') }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include(dossier_url(dossier)) }

    it_behaves_like 'a dossier notification'
  end

  describe '.notify_brouillon_near_deletion' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_brouillon_near_deletion([dossier], dossier.user.email) }

    it { expect(subject.body).to include("n° #{dossier.id} ") }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
  end

  describe '.notify_brouillon_deletion' do
    let(:dossier) { create(:dossier) }

    subject { described_class.notify_brouillon_deletion([dossier.hash_for_deletion_mail], dossier.user.email) }

    it { expect(subject.subject).to eq("Un dossier en brouillon a été supprimé automatiquement") }
    it { expect(subject.body).to include("n° #{dossier.id} (#{dossier.procedure.libelle})") }
  end

  describe '.notify_automatic_deletion_to_user' do
    describe 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }
      let(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier, :expired) }

      subject { described_class.notify_automatic_deletion_to_user([deleted_dossier], dossier.user.email) }

      it { expect(subject.to).to eq([dossier.user.email]) }
      it { expect(subject.subject).to eq("Un dossier a été supprimé automatiquement") }
      it { expect(subject.body).to include("n° #{dossier.id} ") }
      it { expect(subject.body).to include(dossier.procedure.libelle) }
      it { expect(subject.body).to include("nous nous excusons de la gène occasionnée") }
    end

    describe 'termine' do
      let(:dossier) { create(:dossier, :accepte) }
      let(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier, :expired) }

      subject { described_class.notify_automatic_deletion_to_user([deleted_dossier], dossier.user.email) }

      it { expect(subject.to).to eq([dossier.user.email]) }
      it { expect(subject.subject).to eq("Un dossier a été supprimé automatiquement") }
      it { expect(subject.body).to include("n° #{dossier.id} ") }
      it { expect(subject.body).to include(dossier.procedure.libelle) }
      it { expect(subject.body).not_to include("nous nous excusons de la gène occasionnée") }
    end
  end

  describe '.notify_automatic_deletion_to_administration' do
    let(:dossier) { create(:dossier) }
    let(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier, :expired) }

    subject { described_class.notify_automatic_deletion_to_administration([deleted_dossier], dossier.user.email) }

    it { expect(subject.subject).to eq("Un dossier a été supprimé automatiquement") }
    it { expect(subject.body).to include("n° #{dossier.id} (#{dossier.procedure.libelle})") }
  end

  describe '.notify_near_deletion_to_administration' do
    describe 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      subject { described_class.notify_near_deletion_to_administration([dossier], dossier.user.email) }

      it { expect(subject.subject).to eq("Un dossier en construction va bientôt être supprimé") }
      it { expect(subject.body).to include("n° #{dossier.id} ") }
      it { expect(subject.body).to include(dossier.procedure.libelle) }
      it { expect(subject.body).to include("PDF") }
      it { expect(subject.body).to include("Vous avez <b>deux semaines</b> pour commencer l’instruction du dossier.") }
    end

    describe 'termine' do
      let(:dossier) { create(:dossier, :accepte) }

      subject { described_class.notify_near_deletion_to_administration([dossier], dossier.user.email) }

      it { expect(subject.subject).to eq("Un dossier dont le traitement est terminé va bientôt être supprimé") }
      it { expect(subject.body).to include("n° #{dossier.id} ") }
      it { expect(subject.body).to include(dossier.procedure.libelle) }
      it { expect(subject.body).to include("PDF") }
      it { expect(subject.body).to include("Vous avez <b>deux semaines</b> pour archiver le dossier.") }
    end
  end

  describe '.notify_near_deletion_to_user' do
    describe 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      subject { described_class.notify_near_deletion_to_user([dossier], dossier.user.email) }

      it { expect(subject.to).to eq([dossier.user.email]) }
      it { expect(subject.subject).to eq("Un dossier en construction va bientôt être supprimé") }
      it { expect(subject.body).to include("n° #{dossier.id} ") }
      it { expect(subject.body).to include(dossier.procedure.libelle) }
      it { expect(subject.body).to include("PDF") }
      it { expect(subject.body).to include("Vous pouvez retrouver votre dossier pendant encore <b>deux semaines</b>. Vous n’avez rien à faire.") }
      it { expect(subject.body).to include("Si vous souhaitez conserver votre dossier plus longtemps, vous pouvez <b>prolonger sa durée de conservation</b> dans l’interface.") }
    end

    describe 'termine' do
      let(:dossier) { create(:dossier, :accepte) }

      subject { described_class.notify_near_deletion_to_user([dossier], dossier.user.email) }

      it { expect(subject.to).to eq([dossier.user.email]) }
      it { expect(subject.subject).to eq("Un dossier dont le traitement est terminé va bientôt être supprimé") }
      it { expect(subject.body).to include("n° #{dossier.id} ") }
      it { expect(subject.body).to include(dossier.procedure.libelle) }
      it { expect(subject.body).to include("PDF") }
      it { expect(subject.body).to include("Vous pouvez retrouver votre dossier pendant encore <b>deux semaines</b>. Vous n’avez rien à faire.") }
    end
  end

  describe '.notify_groupe_instructeur_changed_to_instructeur' do
    let(:dossier) { create(:dossier) }
    let(:instructeur) { create(:instructeur) }

    subject { described_class.notify_groupe_instructeur_changed(instructeur, dossier) }

    it { expect(subject.subject).to eq("Le dossier nº #{dossier.id} a changé de groupe instructeur") }
    it { expect(subject.body).to include("n° #{dossier.id}") }
    it { expect(subject.body).to include(dossier.procedure.libelle) }
    it { expect(subject.body).to include("Suite à cette modification, vous ne suivez plus ce dossier.") }
  end
end
