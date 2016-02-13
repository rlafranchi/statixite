Fabricator(:site, :class_name => :'Statixite::Site') do
  site_name { Faker::Internet.slug(Faker::Lorem.words(4).join(" "), '-') }
  build_option 'scratch'
end
