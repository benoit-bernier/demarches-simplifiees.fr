require 'rails_helper'

RSpec.describe DossierTransfer, type: :model do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:dossier) { create(:dossier, user: user) }

  describe 'initiate' do
    subject { DossierTransfer.initiate(other_user.email, [dossier]) }

    it 'should send transfer request' do
      expect(subject.email).to eq(other_user.email)
      expect(subject.dossiers).to eq([dossier])
      expect(dossier.transfer).to eq(subject)
      expect(dossier.user).to eq(user)
      expect(dossier.transfer_logs.count).to eq(0)
    end

    describe 'accept' do
      let(:transfer_log) { dossier.transfer_logs.first }

      before do
        DossierTransfer.accept(subject.id, other_user)
        dossier.reload
      end

      it 'should transfer dossier' do
        expect(DossierTransfer.count).to eq(0)
        expect(dossier.transfer).to be_nil
        expect(dossier.user).to eq(other_user)
        expect(dossier.transfer_logs.count).to eq(1)
        expect(transfer_log.dossier).to eq(dossier)
        expect(transfer_log.from).to eq(user.email)
        expect(transfer_log.to).to eq(other_user.email)
      end
    end

    describe 'with_dossiers' do
      before { subject }

      it { expect(DossierTransfer.with_dossiers.count).to eq(1) }

      context "when dossier discarded" do
        before { dossier.discard! }

        it { expect(DossierTransfer.with_dossiers.count).to eq(0) }
      end
    end
  end

  describe '#destroy_and_nullify' do
    let(:transfer) { create(:dossier_transfer) }
    let(:dossier) { create(:dossier, user: user, transfer: transfer) }
    let(:discarded_dossier) { create(:dossier, user: user, transfer: dossier.transfer) }

    before do
      discarded_dossier.discard!
    end

    it 'nullify transfer relationship on dossier' do
      expect(dossier.transfer).to eq(transfer)
      transfer.destroy_and_nullify
      expect(dossier.reload.transfer).to be_nil
    end
  end

  describe '#destroy_stale' do
    let(:transfer) { create(:dossier_transfer, created_at: 1.month.ago) }
    let(:dossier) { create(:dossier, user: user, transfer: transfer) }
    let(:discarded_dossier) { create(:dossier, user: user, transfer: dossier.transfer) }

    before do
      discarded_dossier.discard!
    end

    it 'nullify the transfer on discarded dossier' do
      DossierTransfer.destroy_stale
      expect(DossierTransfer.count).to eq(0)
    end
  end
end
