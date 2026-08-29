# coding: utf-8

User.create!(name: "Sample User",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true)

User.create!(name: "上長A",
             email: "supervisor-a@email.com",
             password: "password",
             password_confirmation: "password",
             supervisor: true)

User.create!(name: "上長B",
             email: "supervisor-b@email.com",
             password: "password",
             password_confirmation: "password",
             supervisor: true)

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password)
end