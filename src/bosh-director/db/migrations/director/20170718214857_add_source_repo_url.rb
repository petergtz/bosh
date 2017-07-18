Sequel.migration do
  change do
    alter_table :release_versions do
      add_column :source_repo_url, String
    end
  end
end
