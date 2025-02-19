describe Dossier do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  describe 'scopes' do
    describe '.default_scope' do
      let!(:dossier) { create(:dossier) }
      let!(:discarded_dossier) { create(:dossier, :discarded) }

      subject { Dossier.all }

      it { is_expected.to match_array([dossier]) }
    end

    describe '.without_followers' do
      let!(:dossier_with_follower) { create(:dossier, :followed, :with_entreprise, user: user) }
      let!(:dossier_without_follower) { create(:dossier, :with_entreprise, user: user) }

      it { expect(Dossier.without_followers.to_a).to eq([dossier_without_follower]) }
    end
  end

  describe 'validations' do
    let(:procedure) { create(:procedure, :for_individual) }
    subject(:dossier) { create(:dossier, procedure: procedure) }

    it { is_expected.to validate_presence_of(:individual) }
  end

  describe 'with_champs' do
    let(:procedure) { create(:procedure, types_de_champ: [build(:type_de_champ, libelle: 'l1', position: 1), build(:type_de_champ, libelle: 'l3', position: 3), build(:type_de_champ, libelle: 'l2', position: 2)]) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    it do
      expect(Dossier.with_champs.find(dossier.id).champs.map(&:libelle)).to match(['l1', 'l2', 'l3'])
    end
  end

  describe 'brouillon_close_to_expiration' do
    let(:procedure) { create(:procedure, :published, duree_conservation_dossiers_dans_ds: 6) }
    let!(:young_dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let!(:expiring_dossier) { create(:dossier, created_at: 175.days.ago, procedure: procedure) }
    let!(:just_expired_dossier) { create(:dossier, created_at: (6.months + 1.hour + 10.seconds).ago, procedure: procedure) }
    let!(:long_expired_dossier) { create(:dossier, created_at: 1.year.ago, procedure: procedure) }

    subject { Dossier.brouillon_close_to_expiration }

    it do
      is_expected.not_to include(young_dossier)
      is_expected.to include(expiring_dossier)
      is_expected.to include(just_expired_dossier)
      is_expected.to include(long_expired_dossier)
    end

    context 'does not include an expiring dossier that has been postponed' do
      before do
        expiring_dossier.update(conservation_extension: 1.month)
        expiring_dossier.reload
      end

      it { is_expected.not_to include(expiring_dossier) }
    end

    context 'when .close_to_expiration' do
      subject { Dossier.close_to_expiration }
      it do
        is_expected.not_to include(young_dossier)
        is_expected.to include(expiring_dossier)
        is_expected.to include(just_expired_dossier)
        is_expected.to include(long_expired_dossier)
      end
    end
  end

  describe 'en_construction_close_to_expiration' do
    let(:procedure) { create(:procedure, :published, duree_conservation_dossiers_dans_ds: 6) }
    let!(:young_dossier) { create(:dossier, procedure: procedure) }
    let!(:expiring_dossier) { create(:dossier, :en_construction, en_construction_at: 175.days.ago, procedure: procedure) }
    let!(:just_expired_dossier) { create(:dossier, :en_construction, en_construction_at: (6.months + 1.hour + 10.seconds).ago, procedure: procedure) }
    let!(:long_expired_dossier) { create(:dossier, :en_construction, en_construction_at: 1.year.ago, procedure: procedure) }

    subject { Dossier.en_construction_close_to_expiration }

    it do
      is_expected.not_to include(young_dossier)
      is_expected.to include(expiring_dossier)
      is_expected.to include(just_expired_dossier)
      is_expected.to include(long_expired_dossier)
    end

    context 'does not include an expiring dossier that has been postponed' do
      before do
        expiring_dossier.update(conservation_extension: 1.month)
        expiring_dossier.reload
      end

      it { is_expected.not_to include(expiring_dossier) }
    end

    context 'when .close_to_expiration' do
      subject { Dossier.close_to_expiration }
      it do
        is_expected.not_to include(young_dossier)
        is_expected.to include(expiring_dossier)
        is_expected.to include(just_expired_dossier)
        is_expected.to include(long_expired_dossier)
      end
    end
    context 'when .termine_or_en_construction_close_to_expiration' do
      subject { Dossier.termine_or_en_construction_close_to_expiration }
      it do
        is_expected.not_to include(young_dossier)
        is_expected.to include(expiring_dossier)
        is_expected.to include(just_expired_dossier)
        is_expected.to include(long_expired_dossier)
      end
    end
  end

  describe 'termine_close_to_expiration' do
    let(:procedure) { create(:procedure, :published, duree_conservation_dossiers_dans_ds: 6, procedure_expires_when_termine_enabled: true) }
    let!(:young_dossier) { create(:dossier, state: :accepte, procedure: procedure, processed_at: 2.days.ago) }
    let!(:expiring_dossier) { create(:dossier, state: :accepte, procedure: procedure, processed_at: 175.days.ago) }
    let!(:just_expired_dossier) { create(:dossier, state: :accepte, procedure: procedure, processed_at: (6.months + 1.hour + 10.seconds).ago) }
    let!(:long_expired_dossier) { create(:dossier, state: :accepte, procedure: procedure, processed_at: 1.year.ago) }

    subject { Dossier.termine_close_to_expiration }

    it do
      is_expected.not_to include(young_dossier)
      is_expected.to include(expiring_dossier)
      is_expected.to include(just_expired_dossier)
      is_expected.to include(long_expired_dossier)
    end

    context 'when .close_to_expiration' do
      subject { Dossier.close_to_expiration }
      it do
        is_expected.not_to include(young_dossier)
        is_expected.to include(expiring_dossier)
        is_expected.to include(just_expired_dossier)
        is_expected.to include(long_expired_dossier)
      end
    end

    context 'when .close_to_expiration' do
      subject { Dossier.termine_or_en_construction_close_to_expiration }
      it do
        is_expected.not_to include(young_dossier)
        is_expected.to include(expiring_dossier)
        is_expected.to include(just_expired_dossier)
        is_expected.to include(long_expired_dossier)
      end
    end
  end

  describe 'with_notifications' do
    let(:dossier) { create(:dossier) }
    let(:instructeur) { create(:instructeur) }

    before do
      create(:follow, dossier: dossier, instructeur: instructeur, messagerie_seen_at: 2.hours.ago)
    end

    subject { instructeur.followed_dossiers.with_notifications }

    context('without changes') do
      it { is_expected.to eq [] }
    end

    context('with changes') do
      context 'when there is a new commentaire' do
        before { dossier.update!(last_commentaire_updated_at: Time.zone.now) }

        it { is_expected.to match([dossier]) }
      end

      context 'when there is a new avis' do
        before { dossier.update!(last_avis_updated_at: Time.zone.now) }

        it { is_expected.to match([dossier]) }
      end

      context 'when a public champ is updated' do
        before { dossier.update!(last_champ_updated_at: Time.zone.now) }

        it { is_expected.to match([dossier]) }
      end

      context 'when a private champ is updated' do
        before { dossier.update!(last_champ_private_updated_at: Time.zone.now) }

        it { is_expected.to match([dossier]) }
      end
    end
  end

  describe 'methods' do
    let(:dossier) { create(:dossier, :with_entreprise, user: user) }
    let(:etablissement) { dossier.etablissement }

    subject { dossier }

    describe '#update_search_terms' do
      let(:etablissement) { build(:etablissement, entreprise_nom: 'Dupont', entreprise_prenom: 'Thomas', association_rna: '12345', association_titre: 'asso de test', association_objet: 'tests unitaires') }
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
      let(:dossier) { create(:dossier, etablissement: etablissement, user: user, procedure: procedure) }
      let(:france_connect_information) { build(:france_connect_information, given_name: 'Chris', family_name: 'Harrisson') }
      let(:user) { build(:user, france_connect_information: france_connect_information) }
      let(:champ_public) { dossier.champs.first }
      let(:champ_private) { dossier.champs_private.first }

      before do
        champ_public.update_attribute(:value, "champ public")
        champ_private.update_attribute(:value, "champ privé")

        dossier.update_search_terms
      end

      it { expect(dossier.search_terms).to eq("#{user.email} champ public #{etablissement.entreprise_siren} #{etablissement.entreprise_numero_tva_intracommunautaire} #{etablissement.entreprise_forme_juridique} #{etablissement.entreprise_forme_juridique_code} #{etablissement.entreprise_nom_commercial} #{etablissement.entreprise_raison_sociale} #{etablissement.entreprise_siret_siege_social} #{etablissement.entreprise_nom} #{etablissement.entreprise_prenom} #{etablissement.association_rna} #{etablissement.association_titre} #{etablissement.association_objet} #{etablissement.siret} #{etablissement.naf} #{etablissement.libelle_naf} #{etablissement.adresse} #{etablissement.code_postal} #{etablissement.localite} #{etablissement.code_insee_localite}") }
      it { expect(dossier.private_search_terms).to eq('champ privé') }

      context 'with an update' do
        before do
          dossier.update(
            champs_attributes: [{ id: champ_public.id, value: 'nouvelle valeur publique' }],
            champs_private_attributes: [{ id: champ_private.id, value: 'nouvelle valeur privee' }]
          )
        end

        it { expect(dossier.search_terms).to include('nouvelle valeur publique') }
        it { expect(dossier.private_search_terms).to include('nouvelle valeur privee') }
      end
    end

    describe '#create' do
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
      let(:dossier) { create(:dossier, procedure: procedure, user: user) }

      it 'builds public and private champs' do
        expect(dossier.champs.count).to eq(1)
        expect(dossier.champs_private.count).to eq(1)
      end
    end

    describe '#build_default_individual' do
      let(:dossier) { build(:dossier, procedure: procedure, user: user) }

      subject do
        dossier.individual = nil
        dossier.build_default_individual
      end

      context 'when the dossier belongs to a procedure for individuals' do
        let(:procedure) { create(:procedure, for_individual: true) }

        it 'creates a default individual' do
          subject
          expect(dossier.individual).to be_present
          expect(dossier.individual.nom).to be_nil
          expect(dossier.individual.prenom).to be_nil
          expect(dossier.individual.gender).to be_nil
        end

        context 'and the user signs-in using France Connect' do
          let(:france_connect_information) { build(:france_connect_information) }
          let(:user) { build(:user, france_connect_information: france_connect_information) }

          it 'fills the individual with the informations from France Connect' do
            subject
            expect(dossier.individual.nom).to eq('DUBOIS')
            expect(dossier.individual.prenom).to eq('Angela Claire Louise')
            expect(dossier.individual.gender).to eq(Individual::GENDER_FEMALE)
          end
        end
      end

      context 'when the dossier belongs to a procedure for moral personas' do
        let(:procedure) { create(:procedure, for_individual: false) }

        it 'doesn’t create a individual' do
          subject
          expect(dossier.individual).to be_nil
        end
      end
    end
  end

  context 'when dossier is followed' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
    let(:instructeur) { create(:instructeur) }
    let(:date1) { 1.day.ago }
    let(:date2) { 1.hour.ago }
    let(:date3) { 1.minute.ago }
    let(:dossier) do
      d = create(:dossier, :with_entreprise, user: user, procedure: procedure)
      Timecop.freeze(date1)
      d.passer_en_construction!
      Timecop.freeze(date2)
      d.passer_en_instruction!(instructeur: instructeur)
      Timecop.freeze(date3)
      d.accepter!(instructeur: instructeur, motivation: "Motivation")
      Timecop.return
      d
    end

    describe "followers_instructeurs" do
      let(:non_following_instructeur) { create(:instructeur) }
      subject { dossier.followers_instructeurs }

      it { expect(subject).to eq [instructeur] }
      it { expect(subject).not_to include(non_following_instructeur) }
    end
  end

  describe '#reset!' do
    let!(:dossier) { create :dossier, :with_entreprise, autorisation_donnees: true }

    subject { dossier.reset! }

    it { expect(dossier.etablissement).not_to be_nil }
    it { expect(dossier.etablissement.exercices).not_to be_empty }
    it { expect(dossier.etablissement.exercices.size).to eq 1 }
    it { expect(dossier.autorisation_donnees).to be_truthy }

    it { expect { subject }.to change(Exercice, :count).by(-1) }
    it { expect { subject }.to change(Etablissement, :count).by(-1) }

    context 'when method reset! is call' do
      before do
        subject
        dossier.reload
      end

      it { expect(dossier.etablissement).to be_nil }
      it { expect(dossier.autorisation_donnees).to be_falsey }
    end
  end

  describe '#champs' do
    let(:procedure) { create(:procedure, types_de_champ: [build(:type_de_champ, :private, libelle: 'l1', position: 1), build(:type_de_champ, :private, libelle: 'l3', position: 3), build(:type_de_champ, :private, libelle: 'l2', position: 2)]) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    it { expect(dossier.champs.pluck(:libelle)).to match(['l1', 'l2', 'l3']) }
  end

  describe '#champs_private' do
    let(:procedure) { create(:procedure, types_de_champ_private: [build(:type_de_champ, :private, libelle: 'l1', position: 1), build(:type_de_champ, :private, libelle: 'l3', position: 3), build(:type_de_champ, :private, libelle: 'l2', position: 2)]) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    it { expect(dossier.champs_private.pluck(:libelle)).to match(['l1', 'l2', 'l3']) }
  end

  describe "#text_summary" do
    let(:service) { create(:service, nom: 'nom du service') }
    let(:procedure) { create(:procedure, libelle: "Démarche", organisation: "Organisme", service: service) }

    context 'when the dossier has been submitted' do
      let(:dossier) { create :dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), depose_at: "31/12/2010".to_date }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier déposé le 31/12/2010 sur la démarche Démarche gérée par l'organisme nom du service") }
    end

    context 'when the dossier has not been submitted' do
      let(:dossier) { create :dossier, procedure: procedure, state: Dossier.states.fetch(:brouillon) }

      subject { dossier.text_summary }

      it { is_expected.to eq("Dossier en brouillon répondant à la démarche Démarche gérée par l'organisme nom du service") }
    end
  end

  describe '#avis_for' do
    let!(:instructeur) { create(:instructeur) }
    let!(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }
    let!(:dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction)) }
    let!(:experts_procedure) { create(:experts_procedure, expert: expert_1, procedure: procedure) }
    let!(:experts_procedure_2) { create(:experts_procedure, expert: expert_2, procedure: procedure) }
    let!(:expert_1) { create(:expert) }
    let!(:expert_2) { create(:expert) }

    context 'when there is a public advice asked from the dossiers instructeur' do
      let!(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure, confidentiel: false) }

      it { expect(dossier.avis_for_instructeur(instructeur)).to match([avis]) }
      it { expect(dossier.avis_for_expert(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for_expert(expert_2)).to match([avis]) }
    end

    context 'when there is a private advice asked from the dossiers instructeur' do
      let!(:avis) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure, confidentiel: true) }

      it { expect(dossier.avis_for_instructeur(instructeur)).to match([avis]) }
      it { expect(dossier.avis_for_expert(expert_1)).to match([avis]) }
      it { expect(dossier.avis_for_expert(expert_2)).not_to match([avis]) }
    end

    context 'when there is a public advice asked from one instructeur to an expert' do
      let!(:avis_1) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure, confidentiel: false) }
      let!(:avis_2) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure_2, confidentiel: false) }

      it { expect(dossier.avis_for_instructeur(instructeur)).to match([avis_1, avis_2]) }
      it { expect(dossier.avis_for_expert(expert_1)).to match([avis_1, avis_2]) }
      it { expect(dossier.avis_for_expert(expert_2)).to match([avis_1, avis_2]) }
    end

    context 'when there is a private advice asked from one instructeur to an expert' do
      let!(:avis_1) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure, confidentiel: true) }
      let!(:avis_2) { create(:avis, dossier: dossier, claimant: instructeur, experts_procedure: experts_procedure_2, confidentiel: true) }

      it { expect(dossier.avis_for_instructeur(instructeur)).to match([avis_1, avis_2]) }
      it { expect(dossier.avis_for_expert(expert_1)).to match([avis_1]) }
      it { expect(dossier.avis_for_expert(expert_2)).to match([avis_2]) }
    end

    context 'when they are a lot of advice' do
      let!(:avis_1) { create(:avis, dossier: dossier, claimant: expert_1, experts_procedure: experts_procedure_2, confidentiel: false, created_at: Time.zone.parse('10/01/2010')) }
      let!(:avis_2) { create(:avis, dossier: dossier, claimant: expert_1, experts_procedure: experts_procedure_2, confidentiel: false, created_at: Time.zone.parse('9/01/2010')) }
      let!(:avis_3) { create(:avis, dossier: dossier, claimant: expert_1, experts_procedure: experts_procedure_2, confidentiel: false, created_at: Time.zone.parse('11/01/2010')) }

      it { expect(dossier.avis_for_instructeur(instructeur)).to match([avis_2, avis_1, avis_3]) }
      it { expect(dossier.avis_for_expert(expert_1)).to match([avis_2, avis_1, avis_3]) }
    end

    context 'when they are a advice published on another dossier' do
      let!(:avis) { create(:avis, dossier: create(:dossier, procedure: procedure), claimant: instructeur, experts_procedure: experts_procedure, confidentiel: false, created_at: Time.zone.parse('9/01/2010')) }

      it { expect(dossier.avis_for_expert(expert_1)).to match([]) }
    end
  end

  describe '#update_state_dates' do
    let(:dossier) { create(:dossier, :brouillon, :with_individual) }
    let(:beginning_of_day) { Time.zone.now.beginning_of_day }
    let(:instructeur) { create(:instructeur) }

    before { Timecop.freeze(beginning_of_day) }
    after { Timecop.return }

    context 'when dossier is en_construction' do
      before do
        dossier.passer_en_construction!
        dossier.reload
      end

      it { expect(dossier.state).to eq(Dossier.states.fetch(:en_construction)) }
      it { expect(dossier.en_construction_at).to eq(beginning_of_day) }
      it { expect(dossier.depose_at).to eq(beginning_of_day) }
      it { expect(dossier.traitement.state).to eq(Dossier.states.fetch(:en_construction)) }
      it { expect(dossier.traitement.processed_at).to eq(beginning_of_day) }

      it 'should keep first en_construction_at date' do
        Timecop.return
        dossier.passer_en_instruction!(instructeur: instructeur)
        dossier.repasser_en_construction!(instructeur)

        expect(dossier.traitements.size).to eq(3)
        expect(dossier.traitements.first.processed_at).to eq(beginning_of_day)
        expect(dossier.traitement.processed_at.round).to eq(dossier.en_construction_at.round)
        expect(dossier.depose_at).to eq(beginning_of_day)
        expect(dossier.en_construction_at).to be > beginning_of_day
      end
    end

    context 'when dossier is en_instruction' do
      let(:dossier) { create(:dossier, :en_construction, :with_individual) }
      let(:instructeur) { create(:instructeur) }

      before do
        dossier.passer_en_instruction!(instructeur: instructeur)
        dossier.reload
      end

      it { expect(dossier.state).to eq(Dossier.states.fetch(:en_instruction)) }
      it { expect(dossier.en_instruction_at).to eq(beginning_of_day) }
      it { expect(dossier.traitement.state).to eq(Dossier.states.fetch(:en_instruction)) }
      it { expect(dossier.traitement.processed_at).to eq(beginning_of_day) }

      it 'should keep first en_instruction_at date if dossier is set to en_construction again' do
        Timecop.return
        dossier.repasser_en_construction!(instructeur)
        dossier.passer_en_instruction!(instructeur: instructeur)

        expect(dossier.traitements.size).to eq(4)
        expect(dossier.traitements.en_construction.first.processed_at).to eq(dossier.depose_at)
        expect(dossier.traitements.en_instruction.first.processed_at).to eq(beginning_of_day)
        expect(dossier.traitement.processed_at.round).to eq(dossier.en_instruction_at.round)
        expect(dossier.en_instruction_at).to be > beginning_of_day
      end
    end

    context 'when dossier is accepte' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual) }

      before do
        dossier.accepter!(instructeur: instructeur)
        dossier.reload
      end

      it { expect(dossier.state).to eq(Dossier.states.fetch(:accepte)) }
      it { expect(dossier.processed_at).to eq(beginning_of_day) }
      it { expect(dossier.traitement.state).to eq(Dossier.states.fetch(:accepte)) }
      it { expect(dossier.traitement.processed_at).to eq(beginning_of_day) }
    end

    context 'when dossier is refuse' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual) }

      before do
        dossier.refuser!(instructeur: instructeur)
        dossier.reload
      end

      it { expect(dossier.state).to eq(Dossier.states.fetch(:refuse)) }
      it { expect(dossier.processed_at).to eq(beginning_of_day) }
      it { expect(dossier.traitement.state).to eq(Dossier.states.fetch(:refuse)) }
      it { expect(dossier.traitement.processed_at).to eq(beginning_of_day) }
    end

    context 'when dossier is sans_suite' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual) }

      before do
        dossier.classer_sans_suite!(instructeur: instructeur)
        dossier.reload
      end

      it { expect(dossier.state).to eq(Dossier.states.fetch(:sans_suite)) }
      it { expect(dossier.processed_at).to eq(beginning_of_day) }
      it { expect(dossier.traitement.state).to eq(Dossier.states.fetch(:sans_suite)) }
      it { expect(dossier.traitement.processed_at).to eq(beginning_of_day) }
    end
  end

  describe '.downloadable_sorted' do
    let(:procedure) { create(:procedure) }
    let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:brouillon)) }
    let!(:dossier2) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:en_construction), depose_at: Time.zone.parse('03/01/2010')) }
    let!(:dossier3) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:en_instruction), depose_at: Time.zone.parse('01/01/2010')) }
    let!(:dossier4) { create(:dossier, :with_entreprise, procedure: procedure, state: Dossier.states.fetch(:en_instruction), archived: true, depose_at: Time.zone.parse('02/01/2010')) }

    subject { procedure.dossiers.downloadable_sorted }

    it { is_expected.to match([dossier3, dossier4, dossier2]) }
  end

  describe "#assign_to_groupe_instructeur" do
    let(:procedure) { create(:procedure) }
    let(:new_groupe_instructeur_new_procedure) { create(:groupe_instructeur) }
    let(:new_groupe_instructeur) { create(:groupe_instructeur, procedure: procedure) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

    it "can change groupe instructeur" do
      expect(dossier.assign_to_groupe_instructeur(new_groupe_instructeur_new_procedure)).to be_falsey
      expect(dossier.groupe_instructeur).not_to eq(new_groupe_instructeur_new_procedure)
    end

    it "can not change groupe instructeur if new groupe is from another procedure" do
      expect(dossier.assign_to_groupe_instructeur(new_groupe_instructeur)).to be_truthy
      expect(dossier.groupe_instructeur).to eq(new_groupe_instructeur)
    end
  end

  describe "#unfollow_stale_instructeurs" do
    let(:procedure) { create(:procedure, :published, :for_individual) }
    let(:instructeur) { create(:instructeur) }
    let(:new_groupe_instructeur) { create(:groupe_instructeur, procedure: procedure) }
    let(:instructeur2) { create(:instructeur, groupe_instructeurs: [procedure.defaut_groupe_instructeur, new_groupe_instructeur]) }
    let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
    let(:last_operation) { DossierOperationLog.last }

    before do
      allow(DossierMailer).to receive(:notify_groupe_instructeur_changed).and_return(double(deliver_later: nil))
    end

    it "unfollows stale instructeurs when groupe instructeur change" do
      instructeur.follow(dossier)
      instructeur2.follow(dossier)
      dossier.reload.assign_to_groupe_instructeur(new_groupe_instructeur, procedure.administrateurs.first)

      expect(dossier.reload.followers_instructeurs).not_to include(instructeur)
      expect(dossier.reload.followers_instructeurs).to include(instructeur2)

      expect(DossierMailer).to have_received(:notify_groupe_instructeur_changed).with(instructeur, dossier)
      expect(DossierMailer).not_to have_received(:notify_groupe_instructeur_changed).with(instructeur2, dossier)

      expect(last_operation.operation).to eq("changer_groupe_instructeur")
      expect(last_operation.dossier).to eq(dossier)
      expect(last_operation.automatic_operation?).to be_falsey
    end
  end

  describe "#send_dossier_received" do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction)) }
    let(:instructeur) { create(:instructeur) }

    before do
      allow(NotificationMailer).to receive(:send_en_instruction_notification).and_return(double(deliver_later: nil))
    end

    it "sends an email when the dossier becomes en_instruction" do
      dossier.passer_en_instruction!(instructeur: instructeur)
      expect(NotificationMailer).to have_received(:send_en_instruction_notification).with(dossier)
    end

    it "does not an email when the dossier becomes accepte" do
      dossier.accepte!
      expect(NotificationMailer).to_not have_received(:send_en_instruction_notification)
    end
  end

  describe "#send_draft_notification_email" do
    include Rails.application.routes.url_helpers

    let(:procedure) { create(:procedure) }
    let(:user) { create(:user) }

    it "send an email when the dossier is created for the very first time" do
      dossier = nil
      expect do
        perform_enqueued_jobs do
          dossier = create(:dossier, procedure: procedure, state: Dossier.states.fetch(:brouillon), user: user)
        end
      end.to change(ActionMailer::Base.deliveries, :size).from(0).to(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq("Retrouvez votre brouillon pour la démarche « #{procedure.libelle} »")
      expect(mail.html_part.body).to include(dossier_url(dossier))
    end

    it "does not send an email when the dossier is created with a non brouillon state" do
      expect { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:accepte), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:refuse), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
      expect { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:sans_suite), user: user) }.not_to change(ActionMailer::Base.deliveries, :size)
    end
  end

  describe "#unspecified_attestation_champs" do
    let(:procedure) { create(:procedure, attestation_template: attestation_template, types_de_champ: types_de_champ, types_de_champ_private: types_de_champ_private) }
    let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
    let(:types_de_champ) { [] }
    let(:types_de_champ_private) { [] }

    subject { dossier.unspecified_attestation_champs.map(&:libelle) }

    context "without attestation template" do
      let(:attestation_template) { nil }

      it { is_expected.to eq([]) }
    end

    context "with attestation template" do
      # Test all combinations:
      # - with tag specified and unspecified
      # - with tag in body and tag in title
      # - with tag correponsing to a champ and an annotation privée
      # - with a dash in the champ libelle / tag
      let(:title) { "voici --specified champ-in-title-- un --unspecified champ-in-title-- beau --specified annotation privée-in-title-- titre --unspecified annotation privée-in-title-- non --numéro du dossier--" }
      let(:body) { "voici --specified champ-in-body-- un --unspecified champ-in-body-- beau --specified annotation privée-in-body-- body --unspecified annotation privée-in-body-- non ?" }
      let(:attestation_template) { build(:attestation_template, title: title, body: body, activated: activated) }

      context "which is disabled" do
        let(:activated) { false }

        it { is_expected.to eq([]) }
      end

      context "wich is enabled" do
        let(:activated) { true }

        let(:types_de_champ) { [tdc_1, tdc_2, tdc_3, tdc_4] }
        let(:types_de_champ_private) { [tdc_5, tdc_6, tdc_7, tdc_8] }

        let(:tdc_1) { build(:type_de_champ, libelle: "specified champ-in-title") }
        let(:tdc_2) { build(:type_de_champ, libelle: "unspecified champ-in-title") }
        let(:tdc_3) { build(:type_de_champ, libelle: "specified champ-in-body") }
        let(:tdc_4) { build(:type_de_champ, libelle: "unspecified champ-in-body") }
        let(:tdc_5) { build(:type_de_champ, private: true, libelle: "specified annotation privée-in-title") }
        let(:tdc_6) { build(:type_de_champ, private: true, libelle: "unspecified annotation privée-in-title") }
        let(:tdc_7) { build(:type_de_champ, private: true, libelle: "specified annotation privée-in-body") }
        let(:tdc_8) { build(:type_de_champ, private: true, libelle: "unspecified annotation privée-in-body") }

        before do
          (dossier.champs + dossier.champs_private)
            .filter { |c| c.libelle.match?(/^specified/) }
            .each { |c| c.update_attribute(:value, "specified") }
        end

        it do
          is_expected.to eq([
            "unspecified champ-in-title",
            "unspecified annotation privée-in-title",
            "unspecified champ-in-body",
            "unspecified annotation privée-in-body"
          ])
        end
      end
    end
  end

  describe '#build_attestation' do
    let(:attestation_template) { nil }
    let(:procedure) { create(:procedure, attestation_template: attestation_template) }

    before :each do
      dossier.attestation = dossier.build_attestation
      dossier.reload
    end

    context 'when the dossier is in en_instruction state ' do
      let!(:dossier) { create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction)) }

      context 'when the procedure has no attestation' do
        it { expect(dossier.attestation).to be_nil }
      end

      context 'when the procedure has an unactivated attestation' do
        let(:attestation_template) { AttestationTemplate.new(activated: false) }

        it { expect(dossier.attestation).to be_nil }
      end

      context 'when the procedure attached has an activated attestation' do
        let(:attestation_template) { AttestationTemplate.new(activated: true) }

        it { expect(dossier.attestation).not_to be_nil }
      end
    end
  end

  describe 'updated_at' do
    let!(:dossier) { create(:dossier) }
    let(:modif_date) { Time.zone.parse('01/01/2100') }

    before { Timecop.freeze(modif_date) }
    after { Timecop.return }

    subject do
      dossier.reload
      dossier.updated_at
    end

    it { is_expected.not_to eq(modif_date) }

    context 'when a champ is modified' do
      before { dossier.champs.first.update_attribute('value', 'yop') }

      it { is_expected.to eq(modif_date) }
    end

    context 'when a commentaire is modified' do
      before { dossier.commentaires << create(:commentaire) }

      it { is_expected.to eq(modif_date) }
    end

    context 'when an avis is modified' do
      before { dossier.avis << create(:avis) }

      it { is_expected.to eq(modif_date) }
    end
  end

  describe '#owner_name' do
    let(:procedure) { create(:procedure) }
    subject { dossier.owner_name }

    context 'when there is no entreprise or individual' do
      let(:dossier) { create(:dossier, individual: nil, procedure: procedure) }

      it { is_expected.to be_nil }
    end

    context 'when there is entreprise' do
      let(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }

      it { is_expected.to eq(dossier.etablissement.entreprise_raison_sociale) }
    end

    context 'when there is an individual' do
      let(:procedure) { create(:procedure, :for_individual) }
      let(:dossier) { create(:dossier, :with_individual, procedure: procedure) }

      it { is_expected.to eq("#{dossier.individual.nom} #{dossier.individual.prenom}") }
    end
  end

  describe "#discard_and_keep_track!" do
    let(:dossier) { create(:dossier, :en_construction) }
    let(:user) { dossier.user }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let(:reason) { :user_request }

    before do
      allow(DossierMailer).to receive(:notify_deletion_to_administration).and_return(double(deliver_later: nil))
    end

    subject! { dossier.discard_and_keep_track!(user, reason) }

    context 'brouillon' do
      let(:dossier) { create(:dossier) }

      it 'hides the dossier' do
        expect(dossier.discarded?).to be_truthy
      end

      it 'do not records the operation in the log' do
        expect(last_operation).to be_nil
      end
    end

    context 'en_construction' do
      it 'hide the dossier but does not discard' do
        expect(dossier.hidden_at).to be_nil
        expect(dossier.hidden_by_user_at).to be_present
      end

      it 'records the operation in the log' do
        expect(last_operation.operation).to eq("supprimer")
        expect(last_operation.automatic_operation?).to be_falsey
      end

      context 'where instructeurs are following the dossier' do
        let(:dossier) { create(:dossier, :en_construction, :followed) }
        let!(:non_following_instructeur) do
          non_following_instructeur = create(:instructeur)
          non_following_instructeur.groupe_instructeurs << dossier.procedure.defaut_groupe_instructeur
          non_following_instructeur
        end
      end

      context 'when dossier is brouillon' do
        let(:dossier) { create(:dossier) }
        it 'do not notifies the procedure administrateur' do
          expect(DossierMailer).not_to have_received(:notify_deletion_to_administration)
        end
      end

      context 'with reason: manager_request' do
        let(:user) { dossier.procedure.administrateurs.first }
        let(:reason) { :manager_request }

        it 'hides the dossier' do
          expect(dossier.discarded?).to be_truthy
        end

        it 'records the operation in the log' do
          expect(last_operation.operation).to eq("supprimer")
          expect(last_operation.automatic_operation?).to be_falsey
        end
      end

      context 'with reason: user_removed' do
        let(:reason) { :user_removed }

        it 'does not discard the dossier' do
          expect(dossier.discarded?).to be_falsy
        end

        it 'hide the dossier' do
          expect(dossier.hidden_by_user_at).to be_present
        end
      end
    end

    context 'termine' do
      let(:dossier) { create(:dossier, state: "accepte", hidden_by_administration_at: 1.hour.ago) }
      before { subject }

      it 'affect the right deletion reason to the dossier' do
        expect(dossier.hidden_by_reason).to eq("user_request")
      end

      it 'discard the dossier' do
        expect(dossier.discarded?).to be_truthy
      end
    end
  end

  describe 'webhook' do
    let(:dossier) { create(:dossier) }
    let(:instructeur) { create(:instructeur) }

    it 'should not call webhook' do
      expect {
        dossier.accepte!
      }.to_not have_enqueued_job(WebHookJob)
    end

    it 'should not call webhook with empty value' do
      dossier.procedure.update_column(:web_hook_url, '')

      expect {
        dossier.accepte!
      }.to_not have_enqueued_job(WebHookJob)
    end

    it 'should not call webhook with blank value' do
      dossier.procedure.update_column(:web_hook_url, '   ')

      expect {
        dossier.accepte!
      }.to_not have_enqueued_job(WebHookJob)
    end

    it 'should call webhook' do
      dossier.procedure.update_column(:web_hook_url, '/webhook.json')

      expect {
        dossier.update_column(:search_terms, 'bonjour')
      }.to_not have_enqueued_job(WebHookJob)

      expect {
        dossier.passer_en_construction!
      }.to have_enqueued_job(WebHookJob)

      expect {
        dossier.update_column(:search_terms, 'bonjour2')
      }.to_not have_enqueued_job(WebHookJob)

      expect {
        dossier.passer_en_instruction!(instructeur: instructeur)
      }.to have_enqueued_job(WebHookJob)
    end
  end

  describe "#can_transition_to_en_construction?" do
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, state: state, procedure: procedure) }

    subject { dossier.can_transition_to_en_construction? }

    context "dossier state is brouillon" do
      let(:state) { Dossier.states.fetch(:brouillon) }
      it { is_expected.to be true }

      context "procedure is closed" do
        before { procedure.close! }
        it { is_expected.to be false }
      end
    end

    context "dossier state is en_construction" do
      let(:state) { Dossier.states.fetch(:en_construction) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:en_instruction) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:accepte) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:refuse) }
      it { is_expected.to be false }
    end

    context "dossier state is en_instruction" do
      let(:state) { Dossier.states.fetch(:sans_suite) }
      it { is_expected.to be false }
    end
  end

  describe "#messagerie_available?" do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    subject { dossier.messagerie_available? }

    context "dossier is brouillon" do
      before { dossier.state = Dossier.states.fetch(:brouillon) }

      it { is_expected.to be false }
    end

    context "dossier is submitted" do
      before { dossier.state = Dossier.states.fetch(:en_instruction) }

      it { is_expected.to be true }
    end

    context "dossier is archived" do
      before { dossier.archived = true }

      it { is_expected.to be false }
    end
  end

  describe '#accepter!' do
    let(:dossier) { create(:dossier, :en_instruction, :with_individual) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let(:operation_serialized) { JSON.parse(last_operation.serialized.download) }
    let!(:instructeur) { create(:instructeur) }
    let!(:now) { Time.zone.parse('01/01/2100') }
    let(:attestation) { Attestation.new }

    before do
      allow(NotificationMailer).to receive(:send_accepte_notification).and_return(double(deliver_later: true))
      allow(dossier).to receive(:build_attestation).and_return(attestation)

      Timecop.freeze(now)
      dossier.accepter!(instructeur: instructeur, motivation: 'motivation')
      dossier.reload
    end

    after { Timecop.return }

    it { expect(dossier.traitements.last.motivation).to eq('motivation') }
    it { expect(dossier.motivation).to eq('motivation') }
    it { expect(dossier.traitements.last.instructeur_email).to eq(instructeur.email) }
    it { expect(dossier.en_instruction_at).to eq(dossier.en_instruction_at) }
    it { expect(dossier.traitements.last.processed_at).to eq(now) }
    it { expect(dossier.processed_at).to eq(now) }
    it { expect(dossier.state).to eq('accepte') }
    it { expect(last_operation.operation).to eq('accepter') }
    it { expect(last_operation.automatic_operation?).to be_falsey }
    it { expect(operation_serialized['operation']).to eq('accepter') }
    it { expect(operation_serialized['dossier_id']).to eq(dossier.id) }
    it { expect(operation_serialized['executed_at']).to eq(last_operation.executed_at.iso8601) }
    it { expect(NotificationMailer).to have_received(:send_accepte_notification).with(dossier) }
    it { expect(dossier.attestation).to eq(attestation) }
  end

  describe '#accepter_automatiquement!' do
    let(:dossier) { create(:dossier, :en_construction, :with_individual) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let!(:now) { Time.zone.parse('01/01/2100') }
    let(:attestation) { Attestation.new }

    before do
      allow(NotificationMailer).to receive(:send_accepte_notification).and_return(double(deliver_later: true))
      allow(dossier).to receive(:build_attestation).and_return(attestation)

      Timecop.freeze(now)
      dossier.accepter_automatiquement!
      dossier.reload
    end

    after { Timecop.return }

    it { expect(dossier.motivation).to eq(nil) }
    it { expect(dossier.en_instruction_at).to eq(now) }
    it { expect(dossier.processed_at).to eq(now) }
    it { expect(dossier.state).to eq('accepte') }
    it { expect(last_operation.operation).to eq('accepter') }
    it { expect(last_operation.automatic_operation?).to be_truthy }
    it { expect(NotificationMailer).to have_received(:send_accepte_notification).with(dossier) }
    it { expect(dossier.attestation).to eq(attestation) }
  end

  describe '#passer_en_instruction!' do
    let(:dossier) { create(:dossier, :en_construction, en_construction_close_to_expiration_notice_sent_at: Time.zone.now) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let(:operation_serialized) { JSON.parse(last_operation.serialized.download) }
    let(:instructeur) { create(:instructeur) }

    before { dossier.passer_en_instruction!(instructeur: instructeur) }

    it { expect(dossier.state).to eq('en_instruction') }
    it { expect(dossier.followers_instructeurs).to include(instructeur) }
    it { expect(dossier.en_construction_close_to_expiration_notice_sent_at).to be_nil }
    it { expect(last_operation.operation).to eq('passer_en_instruction') }
    it { expect(last_operation.automatic_operation?).to be_falsey }
    it { expect(operation_serialized['operation']).to eq('passer_en_instruction') }
    it { expect(operation_serialized['dossier_id']).to eq(dossier.id) }
    it { expect(operation_serialized['executed_at']).to eq(last_operation.executed_at.iso8601) }
  end

  describe '#passer_automatiquement_en_instruction!' do
    let(:dossier) { create(:dossier, :en_construction, en_construction_close_to_expiration_notice_sent_at: Time.zone.now) }
    let(:last_operation) { dossier.dossier_operation_logs.last }
    let(:operation_serialized) { JSON.parse(last_operation.serialized.download) }
    let(:instructeur) { create(:instructeur) }

    before { dossier.passer_automatiquement_en_instruction! }

    it { expect(dossier.followers_instructeurs).not_to include(instructeur) }
    it { expect(dossier.en_construction_close_to_expiration_notice_sent_at).to be_nil }
    it { expect(last_operation.operation).to eq('passer_en_instruction') }
    it { expect(last_operation.automatic_operation?).to be_truthy }
    it { expect(operation_serialized['operation']).to eq('passer_en_instruction') }
    it { expect(operation_serialized['dossier_id']).to eq(dossier.id) }
    it { expect(operation_serialized['executed_at']).to eq(last_operation.executed_at.iso8601) }
  end

  describe "#check_mandatory_champs" do
    let(:procedure) { create(:procedure, :with_type_de_champ) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    it 'no mandatory champs' do
      expect(dossier.check_mandatory_champs).to be_empty
    end

    context "with mandatory champs" do
      let(:procedure) { create(:procedure, :with_type_de_champ_mandatory) }
      let(:champ_with_error) { dossier.champs.first }

      before do
        champ_with_error.value = nil
        champ_with_error.save
      end

      it 'should have errors' do
        errors = dossier.check_mandatory_champs
        expect(errors).not_to be_empty
        expect(errors.first).to eq("Le champ #{champ_with_error.libelle} doit être rempli.")
      end
    end

    context "with mandatory SIRET champ" do
      let(:type_de_champ) { create(:type_de_champ_siret, mandatory: true, procedure: procedure) }
      let(:champ_siret) { create(:champ_siret, type_de_champ: type_de_champ) }

      before do
        dossier.champs << champ_siret
      end

      it 'should not have errors' do
        errors = dossier.check_mandatory_champs
        expect(errors).to be_empty
      end

      context "and invalid SIRET" do
        before do
          champ_siret.update(value: "1234")
          dossier.reload
        end

        it 'should have errors' do
          errors = dossier.check_mandatory_champs
          expect(errors).not_to be_empty
          expect(errors.first).to eq("Le champ #{champ_siret.libelle} doit être rempli.")
        end
      end
    end

    context "with champ repetition" do
      let(:procedure) { create(:procedure, types_de_champ: [type_de_champ_repetition]) }
      let(:type_de_champ_repetition) { build(:type_de_champ_repetition, mandatory: true) }

      before do
        create(:type_de_champ_text, mandatory: true, parent: type_de_champ_repetition)
      end

      context "when no champs" do
        let(:champ_with_error) do
          repetition_champ = dossier.champs.first
          text_champ = repetition_champ.rows.first.first
          text_champ
        end

        it 'should have errors' do
          errors = dossier.check_mandatory_champs
          expect(errors).not_to be_empty
          expect(errors.first).to eq("Le champ #{champ_with_error.libelle} doit être rempli.")
        end
      end

      context "when mandatory champ inside repetition" do
        let(:champ_with_error) { dossier.champs.first.champs.first }

        before do
          dossier.champs.first.add_row
        end

        it 'should have errors' do
          errors = dossier.check_mandatory_champs
          expect(errors).not_to be_empty
          expect(errors.first).to eq("Le champ #{champ_with_error.libelle} doit être rempli.")
        end
      end
    end
  end

  describe '#repasser_en_instruction!' do
    let(:dossier) { create(:dossier, :refuse, :with_attestation, archived: true, termine_close_to_expiration_notice_sent_at: Time.zone.now) }
    let!(:instructeur) { create(:instructeur) }
    let(:last_operation) { dossier.dossier_operation_logs.last }

    before do
      Timecop.freeze
      allow(DossierMailer).to receive(:notify_revert_to_instruction)
        .and_return(double(deliver_later: true))
      dossier.repasser_en_instruction!(instructeur: instructeur)
      dossier.reload
    end

    it { expect(dossier.state).to eq('en_instruction') }
    it { expect(dossier.archived).to be_falsey }
    it { expect(dossier.processed_at).to be_nil }
    it { expect(dossier.motivation).to be_nil }
    it { expect(dossier.attestation).to be_nil }
    it { expect(dossier.termine_close_to_expiration_notice_sent_at).to be_nil }
    it { expect(last_operation.operation).to eq('repasser_en_instruction') }
    it { expect(JSON.parse(last_operation.serialized.download)['author']['email']).to eq(instructeur.email) }
    it { expect(DossierMailer).to have_received(:notify_revert_to_instruction).with(dossier) }

    after { Timecop.return }
  end

  describe '#export_and_attachments_downloadable?' do
    let(:dossier) { create(:dossier, user: user) }

    context "no attachments" do
      it {
        expect(dossier.export_and_attachments_downloadable?).to be true
      }
    end

    context "with a small attachment" do
      it {
        expect(PiecesJustificativesService).to receive(:pieces_justificatives_total_size).and_return(4.megabytes)
        expect(dossier.export_and_attachments_downloadable?).to be true
      }
    end

    context "with a too large attachment" do
      it {
        expect(PiecesJustificativesService).to receive(:pieces_justificatives_total_size).and_return(100.megabytes)
        expect(dossier.export_and_attachments_downloadable?).to be false
      }
    end
  end

  describe '#notify_draft_not_submitted' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:procedure_near_closing) { create(:procedure, :published, auto_archive_on: Time.zone.today + Dossier::REMAINING_DAYS_BEFORE_CLOSING.days) }
    let!(:procedure_closed_later) { create(:procedure, :published, auto_archive_on: Time.zone.today + Dossier::REMAINING_DAYS_BEFORE_CLOSING.days + 1.day) }
    let!(:procedure_closed_before) { create(:procedure, :published, auto_archive_on: Time.zone.today + Dossier::REMAINING_DAYS_BEFORE_CLOSING.days - 1.day) }

    # user 1 has three draft dossiers where one is for procedure that closes in two days ==> should trigger one mail
    let!(:draft_near_closing) { create(:dossier, user: user1, procedure: procedure_near_closing) }
    let!(:draft_before) { create(:dossier, user: user1, procedure: procedure_closed_before) }
    let!(:draft_later) { create(:dossier, user: user1, procedure: procedure_closed_later) }

    # user 2 submitted a draft and en_construction dossier for the same procedure ==> should not trigger the mail
    let!(:draft_near_closing_2) { create(:dossier, :en_construction, user: user2, procedure: procedure_near_closing) }
    let!(:submitted_near_closing_2) { create(:dossier, user: user2, procedure: procedure_near_closing) }

    before do
      allow(DossierMailer).to receive(:notify_brouillon_not_submitted).and_return(double(deliver_later: nil))
      Dossier.notify_draft_not_submitted
    end

    it 'notifies draft is not submitted' do
      expect(DossierMailer).to have_received(:notify_brouillon_not_submitted).once
      expect(DossierMailer).to have_received(:notify_brouillon_not_submitted).with(draft_near_closing)
    end
  end

  describe '#geo_position' do
    let(:lat) { "46.538192" }
    let(:lon) { "2.428462" }
    let(:zoom) { "13" }

    let(:etablissement_geo_adresse_lat) { "40.7143528" }
    let(:etablissement_geo_adresse_lon) { "-74.0059731" }

    let(:result) { { lat: lat, lon: lon, zoom: zoom } }
    let(:dossier) { create(:dossier) }

    it 'should geolocate' do
      expect(dossier.geo_position).to eq(result)
    end

    context 'with etablissement' do
      before do
        Geocoder::Lookup::Test.add_stub(
          dossier.etablissement.geo_adresse, [
            {
              'coordinates' => [etablissement_geo_adresse_lat.to_f, etablissement_geo_adresse_lon.to_f]
            }
          ]
        )
      end

      let(:dossier) { create(:dossier, :with_entreprise) }
      let(:result) { { lat: etablissement_geo_adresse_lat, lon: etablissement_geo_adresse_lon, zoom: zoom } }

      it 'should geolocate' do
        expect(dossier.geo_position).to eq(result)
      end
    end
  end

  describe 'dossier_operation_log after dossier deletion' do
    let(:dossier) { create(:dossier) }
    let(:dossier_operation_log) { create(:dossier_operation_log, dossier: dossier) }

    it 'should nullify dossier link' do
      expect(dossier_operation_log.dossier).to eq(dossier)
      expect(DossierOperationLog.count).to eq(1)
      dossier.destroy
      expect(dossier_operation_log.reload.dossier).to be_nil
      expect(DossierOperationLog.count).to eq(1)
    end
  end

  describe 'discarded_brouillon_expired and discarded_en_construction_expired' do
    let(:administrateur) { create(:administrateur) }
    let(:user) { administrateur.user }
    let(:reason) { DeletedDossier.reasons.fetch(:user_request) }

    before do
      create(:dossier, user: user)
      create(:dossier, :en_construction, user: user)
      create(:dossier, user: user).discard_and_keep_track!(user, reason)
      create(:dossier, :en_construction, user: user).discard_and_keep_track!(user, reason)

      Timecop.travel(2.months.ago) do
        create(:dossier, user: user).discard_and_keep_track!(user, reason)
        create(:dossier, :en_construction, user: user).discard_and_keep_track!(user, reason)

        create(:dossier, user: user).procedure.discard_and_keep_track!(administrateur)
        create(:dossier, :en_construction, user: user).procedure.discard_and_keep_track!(administrateur)
      end
      Timecop.travel(1.week.ago) do
        create(:dossier, user: user).discard_and_keep_track!(user, reason)
        create(:dossier, :en_construction, user: user).discard_and_keep_track!(user, reason)
      end
    end

    it { expect(Dossier.discarded_brouillon_expired.count).to eq(2) }
    it { expect(Dossier.discarded_en_construction_expired.count).to eq(0) }
  end

  describe "discarded procedure dossier should be able to access it's procedure" do
    let(:dossier) { create(:dossier) }
    let(:procedure) { dossier.reload.procedure }

    before { dossier.procedure.discard! }

    it { expect(procedure).not_to be_nil }
    it { expect(procedure.discarded?).to be_truthy }
  end

  describe "to_feature_collection" do
    let(:dossier) { create(:dossier) }
    let(:type_de_champ_carte) { create(:type_de_champ_carte, procedure: dossier.procedure) }
    let(:geo_area) { create(:geo_area, :selection_utilisateur, :polygon) }
    let(:champ_carte) { create(:champ_carte, type_de_champ: type_de_champ_carte, geo_areas: [geo_area]) }

    before do
      dossier.champs << champ_carte
    end

    it 'should have all champs carto' do
      expect(dossier.to_feature_collection).to eq({
        type: 'FeatureCollection',
        id: dossier.id,
        bbox: [2.428439855575562, 46.538491597754714, 2.42824137210846, 46.53841410755813],
        features: [
          {
            type: 'Feature',
            geometry: {
              'coordinates' => [[[2.428439855575562, 46.538476837725796], [2.4284291267395024, 46.53842148758162], [2.4282521009445195, 46.53841410755813], [2.42824137210846, 46.53847314771794], [2.428284287452698, 46.53847314771794], [2.428364753723145, 46.538487907747864], [2.4284291267395024, 46.538491597754714], [2.428439855575562, 46.538476837725796]]],
              'type' => 'Polygon'
            },
            properties: {
              area: 103.6,
              champ_id: champ_carte.stable_id,
              dossier_id: dossier.id,
              id: geo_area.id,
              source: 'selection_utilisateur'
            }
          }
        ]
      })
    end
  end

  describe "with_notifiable_procedure" do
    let(:test_procedure) { create(:procedure) }
    let(:published_procedure) { create(:procedure, :published) }
    let(:closed_procedure) { create(:procedure, :closed) }
    let(:unpublished_procedure) { create(:procedure, :unpublished) }

    let!(:dossier_on_test_procedure) { create(:dossier, procedure: test_procedure) }
    let!(:dossier_on_published_procedure) { create(:dossier, procedure: published_procedure) }
    let!(:dossier_on_closed_procedure) { create(:dossier, procedure: closed_procedure) }
    let!(:dossier_on_unpublished_procedure) { create(:dossier, procedure: unpublished_procedure) }

    let(:notify_on_closed) { false }
    let(:dossiers) { Dossier.with_notifiable_procedure(notify_on_closed: notify_on_closed) }

    it 'should find dossiers with notifiable procedure' do
      expect(dossiers).to match_array([dossier_on_published_procedure, dossier_on_unpublished_procedure])
    end

    context 'when notify on closed is true' do
      let(:notify_on_closed) { true }

      it 'should find dossiers with notifiable procedure' do
        expect(dossiers).to match_array([dossier_on_published_procedure, dossier_on_closed_procedure, dossier_on_unpublished_procedure])
      end
    end
  end

  describe "champs_for_export" do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_datetime, :with_yes_no, :with_explication, :with_commune, :with_repetition) }
    let(:text_type_de_champ) { procedure.types_de_champ.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:text) } }
    let(:yes_no_type_de_champ) { procedure.types_de_champ.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:yes_no) } }
    let(:datetime_type_de_champ) { procedure.types_de_champ.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:datetime) } }
    let(:explication_type_de_champ) { procedure.types_de_champ.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:explication) } }
    let(:commune_type_de_champ) { procedure.types_de_champ.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:communes) } }
    let(:repetition_type_de_champ) { procedure.types_de_champ.find { |type_de_champ| type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }
    let(:repetition_champ) { dossier.champs.find(&:repetition?) }
    let(:repetition_second_revision_champ) { dossier_second_revision.champs.find(&:repetition?) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:dossier_second_revision) { create(:dossier, procedure: procedure) }
    let(:dossier_champs_for_export) { Dossier.champs_for_export(dossier.champs, procedure.types_de_champ_for_procedure_presentation.not_repetition) }
    let(:dossier_second_revision_champs_for_export) { Dossier.champs_for_export(dossier_second_revision.champs, procedure.types_de_champ_for_procedure_presentation.not_repetition) }
    let(:repetition_second_revision_champs_for_export) { Dossier.champs_for_export(repetition_second_revision_champ.champs, procedure.types_de_champ_for_procedure_presentation.repetition) }

    context "when procedure published" do
      before do
        procedure.publish!
        dossier
        procedure.draft_revision.remove_type_de_champ(text_type_de_champ.stable_id)
        procedure.draft_revision.add_type_de_champ(type_champ: TypeDeChamp.type_champs.fetch(:text), libelle: 'New text field')
        procedure.draft_revision.find_or_clone_type_de_champ(yes_no_type_de_champ.stable_id).update(libelle: 'Updated yes/no')
        procedure.draft_revision.find_or_clone_type_de_champ(commune_type_de_champ.stable_id).update(libelle: 'Commune de naissance')
        procedure.draft_revision.find_or_clone_type_de_champ(repetition_type_de_champ.stable_id).update(libelle: 'Repetition')
        procedure.update(published_revision: procedure.draft_revision, draft_revision: procedure.create_new_revision)
        dossier.reload
        procedure.reload
      end

      it "should have champs from all revisions" do
        expect(dossier.types_de_champ.map(&:libelle)).to eq([text_type_de_champ.libelle, datetime_type_de_champ.libelle, "Yes/no", explication_type_de_champ.libelle, commune_type_de_champ.libelle, repetition_type_de_champ.libelle])
        expect(dossier_second_revision.types_de_champ.map(&:libelle)).to eq([datetime_type_de_champ.libelle, "Updated yes/no", explication_type_de_champ.libelle, 'Commune de naissance', "Repetition", "New text field"])
        expect(dossier_champs_for_export.map { |(libelle)| libelle }).to eq([text_type_de_champ.libelle, datetime_type_de_champ.libelle, "Updated yes/no", "Commune de naissance", "Commune de naissance (Code insee)", "New text field"])
        expect(dossier_champs_for_export).to eq(dossier_second_revision_champs_for_export)
        expect(repetition_second_revision_champs_for_export.map { |(libelle)| libelle }).to eq(procedure.types_de_champ_for_procedure_presentation.repetition.map(&:libelle_for_export))
        expect(repetition_second_revision_champs_for_export.first.size).to eq(2)
      end
    end

    context "when procedure brouillon" do
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_explication) }

      it "should not contain non-exportable types de champ" do
        expect(dossier_champs_for_export.map { |(libelle)| libelle }).to eq([text_type_de_champ.libelle])
      end
    end
  end

  describe "remove_titres_identite!" do
    let(:dossier) { create(:dossier, :en_instruction, :followed, :with_individual) }
    let(:type_de_champ_titre_identite) { create(:type_de_champ_titre_identite, procedure: dossier.procedure) }
    let(:champ_titre_identite) { create(:champ_titre_identite, type_de_champ: type_de_champ_titre_identite) }
    let(:type_de_champ_titre_identite_vide) { create(:type_de_champ_titre_identite, procedure: dossier.procedure) }
    let(:champ_titre_identite_vide) { create(:champ_titre_identite, type_de_champ: type_de_champ_titre_identite_vide) }

    before do
      champ_titre_identite_vide.piece_justificative_file.purge
      dossier.champs << champ_titre_identite
      dossier.champs << champ_titre_identite_vide
    end

    it "clean up titres identite on accepter" do
      expect(champ_titre_identite.piece_justificative_file.attached?).to be_truthy
      expect(champ_titre_identite_vide.piece_justificative_file.attached?).to be_falsey
      dossier.accepter!(instructeur: dossier.followers_instructeurs.first, motivation: "yolo!")
      expect(champ_titre_identite.piece_justificative_file.attached?).to be_falsey
    end

    it "clean up titres identite on refuser" do
      expect(champ_titre_identite.piece_justificative_file.attached?).to be_truthy
      expect(champ_titre_identite_vide.piece_justificative_file.attached?).to be_falsey
      dossier.refuser!(instructeur: dossier.followers_instructeurs.first, motivation: "yolo!")
      expect(champ_titre_identite.piece_justificative_file.attached?).to be_falsey
    end

    it "clean up titres identite on classer_sans_suite" do
      expect(champ_titre_identite.piece_justificative_file.attached?).to be_truthy
      expect(champ_titre_identite_vide.piece_justificative_file.attached?).to be_falsey
      dossier.classer_sans_suite!(instructeur: dossier.followers_instructeurs.first, motivation: "yolo!")
      expect(champ_titre_identite.piece_justificative_file.attached?).to be_falsey
    end

    context 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction, :followed, :with_individual) }

      it "clean up titres identite on accepter_automatiquement" do
        expect(champ_titre_identite.piece_justificative_file.attached?).to be_truthy
        expect(champ_titre_identite_vide.piece_justificative_file.attached?).to be_falsey
        dossier.accepter_automatiquement!
        expect(champ_titre_identite.piece_justificative_file.attached?).to be_falsey
      end
    end
  end

  describe '#log_api_entreprise_job_exception' do
    let(:dossier) { create(:dossier) }

    context "add execption to the log" do
      before do
        dossier.log_api_entreprise_job_exception(StandardError.new('My special exception!'))
      end

      it { expect(dossier.api_entreprise_job_exceptions).to eq(['#<StandardError: My special exception!>']) }
    end
  end

  describe "#destroy" do
    let(:transfer) { create(:dossier_transfer) }
    let(:dossier) { create(:dossier, transfer: transfer) }

    before do
      create(:dossier, transfer: transfer)
      create(:attestation, dossier: dossier)
      create(:attestation, dossier: dossier)
    end

    it "can destroy dossier with two attestations" do
      expect(dossier.destroy).to be_truthy
      expect(transfer.reload).not_to be_nil
    end

    context 'discarded' do
      context 'en_construction' do
        let(:dossier) { create(:dossier, :en_construction) }

        before do
          create(:avis, dossier: dossier)
          Timecop.travel(2.weeks.ago) do
            dossier.discard!
          end
          dossier.reload
        end

        it "can destroy dossier with avis" do
          Avis.discarded_en_construction_expired.destroy_all
          expect(dossier.destroy).to be_truthy
        end
      end

      context 'termine' do
        let(:dossier) { create(:dossier, :accepte) }

        before do
          create(:avis, dossier: dossier)
          Timecop.travel(2.weeks.ago) do
            dossier.discard!
          end
          dossier.reload
        end

        it "can destroy dossier with avis" do
          Avis.discarded_termine_expired.destroy_all
          expect(dossier.destroy).to be_truthy
        end
      end
    end
  end

  describe "#spreadsheet_columns" do
    let(:dossier) { create(:dossier) }

    it { expect(dossier.spreadsheet_columns(types_de_champ: [])).to include(["État du dossier", "Brouillon"]) }
  end

  describe '#can_rebase?' do
    let(:procedure) { create(:procedure, :with_type_de_champ_mandatory, :with_yes_no, attestation_template: build(:attestation_template)) }
    let(:attestation_template) { procedure.draft_revision.attestation_template.find_or_revise! }
    let(:type_de_champ) { procedure.types_de_champ.find { |tdc| !tdc.mandatory? } }
    let(:mandatory_type_de_champ) { procedure.types_de_champ.find(&:mandatory?) }

    before { Flipper.enable(:procedure_revisions, procedure) }

    context 'en_construction' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

      before do
        procedure.publish!
        procedure.reload
        dossier
      end

      context 'with added type de champ' do
        before do
          procedure.draft_revision.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "Un champ text"
          })
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with type de champ made optional' do
        before do
          procedure.draft_revision.find_or_clone_type_de_champ(mandatory_type_de_champ.stable_id).update(mandatory: false)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with type de champ made mandatory' do
        before do
          procedure.draft_revision.find_or_clone_type_de_champ(type_de_champ.stable_id).update(mandatory: true)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with removed type de champ' do
        before do
          procedure.draft_revision.remove_type_de_champ(type_de_champ.stable_id)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with attestation template changes' do
        before do
          attestation_template.update(title: "Test")
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end
    end

    context 'en_instruction' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }

      before do
        procedure.publish!
        procedure.reload
        dossier
      end

      context 'with added type de champ' do
        before do
          procedure.draft_revision.add_type_de_champ({
            type_champ: TypeDeChamp.type_champs.fetch(:text),
            libelle: "Un champ text"
          })
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with removed type de champ' do
        before do
          procedure.draft_revision.remove_type_de_champ(type_de_champ.stable_id)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end

      context 'with attestation template changes' do
        before do
          attestation_template.update(title: "Test")
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be true' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_truthy
        end
      end

      context 'with type de champ made optional' do
        before do
          procedure.draft_revision.find_or_clone_type_de_champ(mandatory_type_de_champ.stable_id).update(mandatory: false)
          procedure.publish_revision!
          dossier.reload
        end

        it 'should be false' do
          expect(dossier.pending_changes).not_to be_empty
          expect(dossier.can_rebase?).to be_falsey
        end
      end
    end
  end

  describe "#rebase" do
    let(:procedure) { create(:procedure, :with_type_de_champ_mandatory, :with_yes_no, :with_repetition, :with_datetime) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    let(:yes_no_type_de_champ) { procedure.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:yes_no) } }

    let(:text_type_de_champ) { procedure.types_de_champ.find(&:mandatory?) }
    let(:text_champ) { dossier.champs.find(&:mandatory?) }
    let(:rebased_text_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:text) } }

    let(:datetime_type_de_champ) { procedure.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:datetime) } }
    let(:datetime_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:datetime) } }
    let(:rebased_datetime_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:date) } }

    let(:repetition_type_de_champ) { procedure.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }
    let(:repetition_text_type_de_champ) { repetition_type_de_champ.types_de_champ.find { |tdc| tdc.type_champ == TypeDeChamp.type_champs.fetch(:text) } }
    let(:repetition_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }
    let(:rebased_repetition_champ) { dossier.champs.find { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) } }

    before do
      procedure.publish!
      procedure.draft_revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:text),
        libelle: "Un champ text"
      })
      procedure.draft_revision.find_or_clone_type_de_champ(text_type_de_champ).update(mandatory: false, libelle: "nouveau libelle")
      procedure.draft_revision.find_or_clone_type_de_champ(datetime_type_de_champ).update(type_champ: TypeDeChamp.type_champs.fetch(:date))
      procedure.draft_revision.find_or_clone_type_de_champ(repetition_text_type_de_champ).update(libelle: "nouveau libelle dans une repetition")
      procedure.draft_revision.add_type_de_champ({
        type_champ: TypeDeChamp.type_champs.fetch(:checkbox),
        libelle: "oui ou non",
        parent_id: repetition_type_de_champ.stable_id
      })
      procedure.draft_revision.remove_type_de_champ(yes_no_type_de_champ.stable_id)

      datetime_champ.update(value: Date.today.to_s)
      text_champ.update(value: 'bonjour')
      # Add two rows then remove previous to last row in order to create a "hole" in the sequence
      repetition_champ.add_row
      repetition_champ.add_row
      repetition_champ.champs.where(row: repetition_champ.champs.last.row - 1).destroy_all
      repetition_champ.reload
    end

    it "updates the brouillon champs with the latest revision changes" do
      revision_id = dossier.revision_id
      libelle = text_type_de_champ.libelle

      expect(dossier.revision).to eq(procedure.published_revision)
      expect(dossier.champs.size).to eq(4)
      expect(repetition_champ.rows.size).to eq(2)
      expect(repetition_champ.rows[0].size).to eq(1)
      expect(repetition_champ.rows[1].size).to eq(1)

      procedure.publish_revision!
      perform_enqueued_jobs
      procedure.reload
      dossier.reload

      expect(procedure.revisions.size).to eq(3)
      expect(dossier.revision).to eq(procedure.published_revision)
      expect(dossier.champs.size).to eq(4)
      expect(rebased_text_champ.value).to eq(text_champ.value)
      expect(rebased_text_champ.type_de_champ_id).not_to eq(text_champ.type_de_champ_id)
      expect(rebased_datetime_champ.type_champ).to eq(TypeDeChamp.type_champs.fetch(:date))
      expect(rebased_datetime_champ.value).to be_nil
      expect(rebased_repetition_champ.rows.size).to eq(2)
      expect(rebased_repetition_champ.rows[0].size).to eq(2)
      expect(rebased_repetition_champ.rows[1].size).to eq(2)
      expect(rebased_text_champ.rebased_at).not_to be_nil
      expect(rebased_datetime_champ.rebased_at).not_to be_nil
    end
  end
end
