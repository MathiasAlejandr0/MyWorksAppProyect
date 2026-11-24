import { ACADEMIC_ACTION_NOTE } from '../legal/academicCopy';

export function AcademicInlineNote() {
  return (
    <p className="academic-inline-note" data-testid="academic-demo-note">
      {ACADEMIC_ACTION_NOTE}
    </p>
  );
}
