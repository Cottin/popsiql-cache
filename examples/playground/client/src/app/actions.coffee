
cache = null

module.exports =
	project:
		set: (project) -> cache.commit {Project: {[project.id]: project}}
