## README

### System dependencies

* Ruby 2.2
* Bower
* Postgresql

### How to set up dev env

1. git clone
1. make a copy of database.yml.template and rename it to database.yml (remove .template)
1. configure database.yml
1. rake db:create
1. rake db:schema:load
1. copy secrets.yml.template to secrets.yml
1. configure secrets.yml
1. bower install
1. bundle install