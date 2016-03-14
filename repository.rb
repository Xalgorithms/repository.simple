require 'rugged'

module Tatev
  class Repository
    def initialize(name)
      @root = File.join(ENV.fetch('TATEV_REPOS_ROOT', '/tmp/repos'), name)
      if Dir.exists?(@root)
        @git_repo = Rugged::Repository.new(@root)
      else
        @git_repo = Rugged::Repository.init_at(@root)
      end
    end

    def add(invocation_id, context_id, content)
      store_file(invocation_id, context_id, content, "Original: #{invocation_id}/#{context_id}")
    end

    def update(invocation_id, context_id, content)
      store_file(invocation_id, context_id, content, "Updated: #{invocation_id}/#{context_id}")
    end

    def get(invocation_id, context_id, &bl)
      fn = make_path(invocation_id, context_id)
      content = MultiJson.decode(File.read(fn))
      bl.call(content) if bl
      content
    end
    
    private

    def store_file(invocation_id, context_id, content, message)
      fn = store_content(invocation_id, context_id, MultiJson.encode(content))
      commit_file(fn, message)
    end

    def make_path(invocation_id, context_id)
      invocation_path = File.join(@root, invocation_id)
      if !Dir.exists?(invocation_path)
        Dir.mkdir(invocation_path)
      end

      File.join(invocation_path, "#{context_id}.json")
    end
    
    def store_content(invocation_id, context_id, content)
      fn = make_path(invocation_id, context_id)
      File.open(fn, 'w') do |f|
        f.write(content)
      end

      File.join(invocation_id, "#{context_id}.json")
    end

    def add_to_index(fn)
      index = @git_repo.index
      index.add(path: fn, oid: Rugged::Blob.from_workdir(@git_repo, fn), mode: 0100644)
      commit_tree = index.write_tree(@git_repo)
      index.write

      commit_tree
    end

    def create_commit(commit_tree, m)
      who = {
        email: "registry@xalgorithms.org",
        name: "Registry",
        time: Time.now,
      }
      
      opts = {
        author: who,
        committer: who,
        message: m,
        parents: @git_repo.empty? ? [] : [@git_repo.head.target],
        tree: commit_tree,
        update_ref: 'HEAD',
      }
      Rugged::Commit.create(@git_repo, opts)
    end
    
    def commit_file(fn, m)
      # @git_repo.checkout('refs/heads/master')
      create_commit(add_to_index(fn), m)
    end
  end
end
