username = 'root'
password = 'root'
email = 'root@example.com'
blogname = 'imalog'

user = User.create! name: username, profile: '', email: email, password: password, password_confirmation: password
syntax = MarkupSyntax.create! name: 'rebrit', class_name: 'Rebrit::Compiler'
blog = Blog.create! user: user, name: blogname, markup_syntax: syntax
