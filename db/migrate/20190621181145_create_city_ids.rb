class CreateCityIds < ActiveRecord::Migration[5.2]
  def change
    create_table :city_ids do |t|
      t.string :city
      t.string :city_id

      t.timestamps
    end
  end
end
