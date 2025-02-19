describe PasswordComplexityController, type: :controller do
  describe '#show' do
    let(:params) do
      { user: { password: 'moderately complex password' } }
    end

    subject { get :show, format: :js, params: params, xhr: true }

    it 'computes a password score' do
      subject
      expect(assigns(:score)).to eq(3)
    end

    context 'with a different resource name' do
      let(:params) do
        { super_admin: { password: 'moderately complex password' } }
      end

      it 'computes a password score' do
        subject
        expect(assigns(:score)).to eq(3)
      end
    end

    context 'when rendering the view' do
      render_views

      it 'renders Javascript that updates the password complexity meter' do
        subject
        expect(response.body).to include('#complexity-label')
        expect(response.body).to include('#complexity-bar')
      end
    end
  end
end
