# frozen_string_literal: true

puts "\n== Seeding neighbry-api =="

# == Users ==
puts "-- Users"
[
  { email: "demo@neighbry.com",  name: "Demo User",  password: "password123" },
  { email: "admin@neighbry.com", name: "Admin",       password: "password123" }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  if user.new_record?
    user.assign_attributes(name: attrs[:name], password: attrs[:password], password_confirmation: attrs[:password])
    user.save!
    puts "   Criado: #{attrs[:email]}"
  else
    puts "   Já existe: #{attrs[:email]}"
  end
end

puts "\n== Seed concluído =="
puts "   Users: #{User.count}"
puts "   Login: demo@neighbry.com / password123"
