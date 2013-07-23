require 'r10k/git/cache'
require 'r10k/deployment/environment'
require 'r10k/util/purgeable'

module R10K
class Deployment
class Source
  # Represents a git repository to map branches to environments
  #
  # This module is backed with a bare git cache that's used to enumerate
  # branches. The cache isn't used for anything else here, but all environments
  # using that remote will be able to reuse the cache.

  # @!attribute [r] name
  #   @return [String] The short name for the deployment source
  attr_reader :name

  # @!attribute [r] source
  #   @return [String] The git remote to use for environments
  attr_reader :remote

  # @!attribute [r] basedir
  #   @return [String] The base directory to deploy the environments into
  attr_reader :basedir

  # @!attribute [r] environments
  #   @return [Array<R10K::Deployment::Environment>] All environments for this source
  attr_reader :environments
  
  # @!attribute [r] sticky
  #   @return [boolean]  Whether this source is in sticky mode. Sticky mode implies 
  #                      environments will not be purged when remove from Git 
  attr_reader :sticky

  def self.vivify(name, attrs)
    remote  = (attrs.delete(:remote) || attrs.delete('remote'))
    basedir = (attrs.delete(:basedir) || attrs.delete('basedir'))
    sticky = (attrs.delete(:sticky) || attrs.delete('sticky') || false)


    raise ArgumentError, "Unrecognized attributes for #{self.name}: #{attrs.inspect}" unless attrs.empty?
    new(name, remote, basedir, sticky)
  end

  def initialize(name, remote, basedir, sticky)
    @name    = name
    @remote  = remote
    @basedir = basedir

    @cache   = R10K::Git::Cache.new(@remote)
    @sticky  = sticky
    
    load_environments
  end
  
  def sticky?
    @sticky
  end

  def fetch_remote
    @cache.sync
    load_environments
  end

  include R10K::Util::Purgeable

  def exists?
    File.exist? @basedir
  end

  def managed_directory
    @basedir
  end

  # List all environments that should exist in the basedir for this source
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    @environments.map {|env| env.dirname }
  end

  private

  def load_environments
    if @cache.cached?
      @environments = @cache.branches.map do |branch|
        R10K::Deployment::Environment.new(branch, @remote, @basedir)
      end
    else
      @environments = []
    end
  end
end
end
end
