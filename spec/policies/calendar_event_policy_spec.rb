require 'rails_helper'

RSpec.describe CalendarEventPolicy, type: :policy do
  let(:department) { create(:department) }
  let(:other_department) { create(:department) }
  let(:program) { create(:program, department: department) }
  let(:other_program) { create(:program, department: other_department) }
  let(:calendar_event) { create(:calendar_event, program: program) }
  let(:other_calendar_event) { create(:calendar_event, program: other_program) }
  subject { described_class }

  describe '#index?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, CalendarEvent).index?).to be true
      end
    end

    context 'as department admin' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, CalendarEvent).index?).to be true
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'denies access' do
        expect(subject.new(user, CalendarEvent).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, calendar_event).show?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, calendar_event).show?).to be true
      end
    end

    context 'as department admin of other department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: other_department)
        user
      end

      it 'denies access' do
        expect(subject.new(user, calendar_event).show?).to be false
      end
    end
  end

  describe '#create?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, CalendarEvent.new(program: program)).create?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, CalendarEvent.new(program: program)).create?).to be true
      end
    end
  end

  describe '#update?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, calendar_event).update?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, calendar_event).update?).to be true
      end
    end
  end

  describe '#destroy?' do
    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'allows access' do
        expect(subject.new(user, calendar_event).destroy?).to be true
      end
    end

    context 'as department admin of the department' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'allows access' do
        expect(subject.new(user, calendar_event).destroy?).to be true
      end
    end
  end

  describe 'Scope' do
    let!(:event1) { calendar_event }
    let!(:event2) { other_calendar_event }

    context 'as super admin' do
      let(:user) { create(:user, :with_super_admin_role) }

      it 'returns all calendar events' do
        resolved = CalendarEventPolicy::Scope.new(user, CalendarEvent).resolve
        expect(resolved).to include(event1, event2)
      end
    end

    context 'as department admin' do
      let(:user) do
        user = create(:user, :with_department_admin_role)
        DepartmentAdmin.create!(user: user, department: department)
        user
      end

      it 'returns only events from their departments' do
        resolved = CalendarEventPolicy::Scope.new(user, CalendarEvent).resolve
        expect(resolved).to include(event1)
        expect(resolved).not_to include(event2)
      end
    end

    context 'as student' do
      let(:user) { create(:user, :with_student_role) }

      it 'returns no events' do
        resolved = CalendarEventPolicy::Scope.new(user, CalendarEvent).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
