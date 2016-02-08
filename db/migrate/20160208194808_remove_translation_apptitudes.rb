class RemoveTranslationApptitudes < ActiveRecord::Migration
  def change
    drop_table :translation_aptitudes
    SearchAttribute.where(name: "translation_aptitudes").destroy_all
  end
end
