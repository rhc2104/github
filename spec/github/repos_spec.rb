require 'spec_helper'

describe Github::Repos do

  let(:github) { Github.new }
  let(:user)   { 'peter-murach' }
  let(:repo)   { 'github' }

  describe "branches" do
    context "resource found" do
      before do
        stub_get("/repos/#{user}/#{repo}/branches").
          to_return(:body => fixture('repos/branches.json'), :status => 200, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should raise error when no user/repo parameters" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.branches
        }.to raise_error(ArgumentError, /\[user\] parameter cannot be nil/)
      end

      it "should raise error when no repository" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.branches user
        }.to raise_error(ArgumentError, /\[repo\] parameter cannot be nil/)
      end

      it "should find resources" do
        github.repos.branches user, repo
        a_get("/repos/#{user}/#{repo}/branches").should have_been_made
      end

      it "should return array of resources" do
        branches = github.repos.branches user, repo
        branches.should be_an Array
        branches.should have(1).items
      end

      it "should get branch information" do
        branches = github.repos.branches user, repo
        branches.first.name.should == 'master'
      end

      it "should yield to a block" do
        github.repos.should_receive(:branches).with(user, repo).and_yield('web')
        github.repos.branches(user, repo) { |param| 'web'}
      end
    end

    context "resource not found" do
      before do
        stub_get("/repos/#{user}/#{repo}/branches").
          to_return(:body => fixture('repos/branches.json'), :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})

      end

      it "should fail to get resource" do
        expect {
          github.repos.branches user, repo
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # branches

  describe "contributors" do
    context "resource found" do
      before do
        stub_get("/repos/#{user}/#{repo}/contributors").
          to_return(:body => fixture('repos/contributors.json'), :status => 200, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should raise error when no user/repo parameters" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.contributors
        }.to raise_error(ArgumentError, /\[user\] parameter cannot be nil/)
      end

      it "should raise error when no repository" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.contributors user
        }.to raise_error(ArgumentError, /\[repo\] parameter cannot be nil/)
      end

      it "should find resources" do
        github.repos.contributors user, repo
        a_get("/repos/#{user}/#{repo}/contributors").should have_been_made
      end

      it "should return array of resources" do
        contributors = github.repos.contributors user, repo
        contributors.should be_an Array
        contributors.should have(1).items
      end

      it "should get branch information" do
        contributors = github.repos.contributors user, repo
        contributors.first.login.should == 'octocat'
      end

      it "should yield to a block" do
        github.repos.should_receive(:contributors).with(user, repo).and_yield('web')
        github.repos.contributors(user, repo) { |param| 'web'}
      end
    end

    context "resource not found" do
      before do
        stub_get("/repos/#{user}/#{repo}/contributors").
          to_return(:body => fixture('repos/contributors.json'), :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})

      end

      it "should fail to get resource" do
        expect {
          github.repos.contributors user, repo
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # contributors

  describe "create_repo" do
    let(:inputs) { {:name => 'web', :description => "This is your first repo", :homepage => "https://github.com", :public => true, :has_issues => true, :has_wiki => true}}

    context "resource created successfully for the authenticated user" do
      before do
        github.user = nil
        github.oauth_token = OAUTH_TOKEN
        stub_post("/user/repos?access_token=#{OAUTH_TOKEN}").with(inputs).
          to_return(:body => fixture('repos/repo.json'), :status => 201,:headers => {:content_type => "application/json; charset=utf-8"} )
      end

      after do
        github.user, github.oauth_token = nil, nil
      end

      it "should faile to create resource if 'name' inputs is missing" do
        expect {
          github.repos.create_repo inputs.except(:name)
        }.to raise_error(ArgumentError)
      end

      it "should create resource" do
        github.repos.create_repo inputs
        a_post("/user/repos?access_token=#{OAUTH_TOKEN}").with(inputs).should have_been_made
      end

      it "should return the resource" do
        repository = github.repos.create_repo inputs
        repository.name.should == 'Hello-World'
      end

      it "should return mash type" do
        repository = github.repos.create_repo inputs
        repository.should be_a Hashie::Mash
      end
    end

    context "resource created for the authenticated user belonging to organization" do
      let(:org) { '37signals' }
      before do
        github.user = nil
        github.oauth_token = OAUTH_TOKEN
        stub_post("/orgs/#{org}/repos?access_token=#{OAUTH_TOKEN}").with(inputs).
          to_return(:body => fixture('repos/repo.json'), :status => 201,:headers => {:content_type => "application/json; charset=utf-8"} )
      end

      after do
        github.user, github.oauth_token = nil, nil
      end

      it "should get the resource" do
        github.repos.create_repo inputs.merge(:org => org)
        a_post("/orgs/#{org}/repos?access_token=#{OAUTH_TOKEN}").with(inputs).should have_been_made
      end
    end

    context "failed to create" do
      before do
        github.user = nil
        github.oauth_token = OAUTH_TOKEN
        stub_post("/user/repos?access_token=#{OAUTH_TOKEN}").with(inputs).
          to_return(:body => '', :status => 404,:headers => {:content_type => "application/json; charset=utf-8"} )
      end

      after do
        github.user, github.oauth_token = nil, nil
      end

      it "should faile to retrieve resource" do
        expect {
          github.repos.create_repo inputs
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end

  describe "edit_repo" do
    let(:inputs) { {:name => 'web', :description => "This is your first repo", :homepage => "https://github.com", :public => true, :has_issues => true, :has_wiki => true}}

    context "resource edited successfully" do
      before do
        stub_patch("/repos/#{user}/#{repo}").with(inputs).
          to_return(:body => fixture("repos/repo.json"), :status => 200, :headers => { :content_type => "application/json; charset=utf-8"})
      end

      it "should fail to edit without 'user/repo' parameters" do
        github.user, github.repo = nil, nil
        expect { github.repos.edit_repo }.to raise_error(ArgumentError)
      end

      it "should fail to edit resource without 'name' parameter" do
        expect{
          github.repos.edit_hook user, repo, inputs.except(:name)
        }.to raise_error(ArgumentError)
      end

      it "should edit the resource" do
        github.repos.edit_repo user, repo, inputs
        a_patch("/repos/#{user}/#{repo}").with(inputs).should have_been_made
      end

      it "should return resource" do
        repository = github.repos.edit_repo user, repo, inputs
        repository.should be_a Hashie::Mash
      end

      it "should be able to retrieve information" do
        repository = github.repos.edit_repo user, repo, inputs
        repository.name.should == 'Hello-World'
      end

    end

    context "failed to edit resource" do
      before do
        stub_patch("/repos/#{user}/#{repo}").with(inputs).
          to_return(:body => fixture("repos/repo.json"), :status => 404, :headers => { :content_type => "application/json; charset=utf-8"})

      end

      it "should fail to find resource" do
        expect {
          github.repos.edit_repo user, repo, inputs
        }.to raise_error(Github::ResourceNotFound)
      end
    end

  end # edit_repo

  describe "get_repo" do
    context "resource found" do
      before do
        stub_get("/repos/#{user}/#{repo}").
          to_return(:body => fixture('repos/repo.json'), :status => 200, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should raise error when no user/repo parameters" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.get_repo
        }.to raise_error(ArgumentError, /\[user\] parameter cannot be nil/)
      end

      it "should raise error when no repository" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.get_repo user
        }.to raise_error(ArgumentError, /\[repo\] parameter cannot be nil/)
      end

      it "should find resources" do
        github.repos.get_repo user, repo
        a_get("/repos/#{user}/#{repo}").should have_been_made
      end

      it "should return repository mash" do
        repository = github.repos.get_repo user, repo
        repository.should be_a Hashie::Mash
      end

      it "should get repository information" do
        repository = github.repos.get_repo user, repo
        repository.name.should == 'Hello-World'
      end
    end

    context "resource not found" do
      before do
        stub_get("/repos/#{user}/#{repo}").
          to_return(:body => '', :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should fail to get resource" do
        expect {
          github.repos.get_repo user, repo
        }.to raise_error(Github::ResourceNotFound)
      end

    end
  end # get_repo

  describe "languages" do
    context "resource found" do
      before do
        stub_get("/repos/#{user}/#{repo}/languages").
          to_return(:body => fixture('repos/languages.json'), :status => 200, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should raise error when no user/repo parameters" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.languages
        }.to raise_error(ArgumentError, /\[user\] parameter cannot be nil/)
      end

      it "should raise error when no repository" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.languages user
        }.to raise_error(ArgumentError, /\[repo\] parameter cannot be nil/)
      end

      it "should find resources" do
        github.repos.languages user, repo
        a_get("/repos/#{user}/#{repo}/languages").should have_been_made
      end

      it "should return hash of languages" do
        languages = github.repos.languages user, repo
        languages.should be_an Hash
        languages.should have(2).keys
      end

      it "should get language information" do
        languages = github.repos.languages user, repo
        languages.keys.first.should == 'Ruby'
      end

      it "should yield to a block" do
        github.repos.should_receive(:languages).with(user, repo).and_yield('web')
        github.repos.languages(user, repo) { |param| 'web'}
      end
    end

    context "resource not found" do
      before do
        stub_get("/repos/#{user}/#{repo}/languages").
          to_return(:body => '', :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})

      end

      it "should fail to get resource" do
        expect {
          github.repos.languages user, repo
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # languages

  describe "repos" do
    context "resource found for authenticated user" do
      before do
        github.user = nil
        github.oauth_token = OAUTH_TOKEN
        stub_get("/user/repos?access_token=#{OAUTH_TOKEN}").
          to_return(:body => fixture('repos/repos.json'), :status => 200,:headers => {:content_type => "application/json; charset=utf-8"} )
      end

      after do
        github.oauth_token = nil
        github.user, github.repo = nil, nil
      end

      it "should faile if user unauthenticated" do
        github.oauth_token = nil
        stub_get("/user/repos").
          to_return(:body => '', :status => 401,:headers => {:content_type => "application/json; charset=utf-8"} )
        expect { github.repos.repos}.to raise_error(Github::Unauthorised)
      end

      it "should get the resources" do
        github.repos.repos
        a_get("/user/repos?access_token=#{OAUTH_TOKEN}").should have_been_made
      end

      it "should return array of resources" do
        repositories = github.repos.repos
        repositories.should be_an Array
        repositories.should have(1).items
      end

      it "should get resource information" do
        repositories = github.repos.repos
        repositories.first.name.should == 'Hello-World'
      end

      it "should yield repositories to a block" do
        github.repos.should_receive(:repos).and_yield('octocat')
        github.repos.repos { |repo| 'octocat' }
      end
    end

    context "resource found for organization" do
      let(:org) { '37signals' }

      before do
        github.user = nil
        github.oauth_token = nil
        stub_get("/orgs/#{org}/repos").
          to_return(:body => fixture('repos/repos.json'), :status => 200,:headers => {:content_type => "application/json; charset=utf-8"} )
      end

      it "should get the resources" do
        github.repos.repos :org => org
        a_get("/orgs/#{org}/repos").should have_been_made
      end

    end

    context "resource found for organization" do
      before do
        stub_get("/users/#{user}/repos").
          to_return(:body => fixture('repos/repos.json'), :status => 200,:headers => {:content_type => "application/json; charset=utf-8"} )
      end

      it "should get the resources" do
        github.repos.repos :user => user
        a_get("/users/#{user}/repos").should have_been_made
      end
    end

    context "rosource not found for authenticated user" do
      before do
        github.user = nil
        github.oauth_token = OAUTH_TOKEN
        stub_get("/user/repos?access_token=#{OAUTH_TOKEN}").
          to_return(:body => '', :status => 404,:headers => {:content_type => "application/json; charset=utf-8"} )
      end

      after do
        github.oauth_token = nil
        github.user, github.repo = nil, nil
      end

      it "fail to find resources" do
        expect { github.repos.repos }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # repos

  describe "tags" do
    context "resource found" do
      before do
        stub_get("/repos/#{user}/#{repo}/tags").
          to_return(:body => fixture('repos/tags.json'), :status => 200, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should raise error when no user/repo parameters" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.tags
        }.to raise_error(ArgumentError, /\[user\] parameter cannot be nil/)
      end

      it "should raise error when no repository" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.tags user
        }.to raise_error(ArgumentError, /\[repo\] parameter cannot be nil/)
      end

      it "should find resources" do
        github.repos.tags user, repo
        a_get("/repos/#{user}/#{repo}/tags").should have_been_made
      end

      it "should return array of resources" do
        tags = github.repos.tags user, repo
        tags.should be_an Array
        tags.should have(1).items
      end

      it "should get tag information" do
        tags = github.repos.tags user, repo
        tags.first.name.should == 'v0.1'
      end

      it "should yield to a block" do
        github.repos.should_receive(:tags).with(user, repo).and_yield('web')
        github.repos.tags(user, repo) { |param| 'web'}
      end
    end

    context "resource not found" do
      before do
        stub_get("/repos/#{user}/#{repo}/tags").
          to_return(:body => fixture('repos/branches.json'), :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})

      end

      it "should fail to get resource" do
        expect {
          github.repos.tags user, repo
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end #tags

  describe "teams" do
    context "resource found" do
      before do
        stub_get("/repos/#{user}/#{repo}/teams").
          to_return(:body => fixture('repos/teams.json'), :status => 200, :headers => {:content_type => "application/json; charset=utf-8"})
      end

      it "should raise error when no user/repo parameters" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.teams
        }.to raise_error(ArgumentError, /\[user\] parameter cannot be nil/)
      end

      it "should raise error when no repository" do
        github.user, github.repo = nil, nil
        expect {
          github.repos.teams user
        }.to raise_error(ArgumentError, /\[repo\] parameter cannot be nil/)
      end

      it "should find resources" do
        github.repos.teams user, repo
        a_get("/repos/#{user}/#{repo}/teams").should have_been_made
      end

      it "should return array of resources" do
        teams = github.repos.teams user, repo
        teams.should be_an Array
        teams.should have(1).items
      end

      it "should get branch information" do
        teams = github.repos.teams user, repo
        teams.first.name.should == 'Owners'
      end

      it "should yield to a block" do
        github.repos.should_receive(:teams).with(user, repo).and_yield('web')
        github.repos.teams(user, repo) { |param| 'web'}
      end
    end

    context "resource not found" do
      before do
        stub_get("/repos/#{user}/#{repo}/teams").
          to_return(:body => fixture('repos/teams.json'), :status => 404, :headers => {:content_type => "application/json; charset=utf-8"})

      end

      it "should fail to get resource" do
        expect {
          github.repos.teams user, repo
        }.to raise_error(Github::ResourceNotFound)
      end
    end
  end # teams

end # Github::Repos
