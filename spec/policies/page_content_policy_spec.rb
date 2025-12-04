require 'rails_helper'

RSpec.describe PageContentPolicy, type: :policy do
  let(:page_content) { create(:page_content) }
  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, PageContent).index?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, PageContent).index?).to be false
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'denies access' do
        expect(subject.new(user, PageContent).index?).to be false
      end
    end

    context 'as unauthenticated user' do
      let(:user) { nil }

      it 'denies access' do
        expect(subject.new(user, PageContent).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, page_content).show?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, page_content).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, PageContent).create?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, PageContent).create?).to be false
      end
    end
  end

  describe '#new?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, PageContent).new?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, PageContent).new?).to be false
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, page_content).update?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, page_content).update?).to be false
      end
    end
  end

  describe '#edit?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, page_content).edit?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, page_content).edit?).to be false
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, page_content).destroy?).to be true
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'denies access' do
        expect(subject.new(user, page_content).destroy?).to be false
      end
    end
  end

  describe 'Scope' do
    let!(:page_content1) { create(:page_content) }
    let!(:page_content2) { create(:page_content) }

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'returns all page contents' do
        resolved = PageContentPolicy::Scope.new(user, PageContent).resolve
        expect(resolved).to include(page_content1, page_content2)
      end
    end

    context 'as department admin' do
      let(:user) { create(:user, :with_department_admin_role) }

      it 'returns no page contents' do
        resolved = PageContentPolicy::Scope.new(user, PageContent).resolve
        expect(resolved).to be_empty
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'returns no page contents' do
        resolved = PageContentPolicy::Scope.new(user, PageContent).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
