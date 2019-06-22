# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
json = ActiveSupport::JSON.decode(File.read('db/city_ids.json'))

json.each do |data|
  CityId.create(city:data['city'], city_id:data['id'])
end
