# Providing a universal API for different storages

class Storage
end

class CouchDBStorage < Storage
end

class LocalFSStorage < Storage
end
