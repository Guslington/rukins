# Rukins

Manage cloudformation stacks with templates created with cfndsl 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rukins'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rukins

## Usage

### Credentials

Credentials can be specified for each camand using IAM role, profile from the AWS redentials file or leave blank to use your defaults

    $ rukins create --region=ap-southeast-2 --stack_name=dev01 --role=role_name --account=dev # specify the role

    $ rukins create --region=ap-southeast-2 --stack_name=dev01 --profile=profile_name --account=dev # specify the profile

    $ rukins create --region=ap-southeast-2 --stack_name=dev01 --account=dev # leave aws-sdk to find credentials

### Commands

Check version

    $ rukins rukins -v

Help!

    $ rukins help # show all commands and required parameters

    $ rukins help [COMMAND] # show all parameters for a specific command

Create new cloudformation project

    $ rukins new -p project

Generate JSON templates with cfndsl into output directory

    $ rukins generate

Validate JSON cloudfromation templates agains Aws

    $ rukins validate -r ap-southeast-2

Copy JSON templates to s3 source bucket

    $ rukins deploy -r ap-southeast-2

Create cloudformation template

    $ rukins create -r ap-southeast-2 -s dev01 -a dev

Update cloudformation template

    $ rukins update -r ap-southeast-2 -s dev01 -a dev

Delete cloudformation template

    $ rukins delete -r ap-southeast-2 -s dev01 -a dev

Wait for cloudformation task to complete

    $ rukins wait -r ap-southeast-2 -s dev01 -a dev


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/guslington/rukins.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

