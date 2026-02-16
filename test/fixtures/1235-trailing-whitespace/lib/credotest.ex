defmodule Mix.Tasks.Publish do
	@moduledoc """
	Publishes the package to hex.pm with pre-flight checks and version management.

	## Usage

	    mix publish             # Full publish workflow
	    mix publish --dry-run   # Run checks and build, but don't publish
	    mix publish --skip-checks # Skip pre-flight checks
	    mix publish --revert    # Revert current version from hex.pm
	    mix publish --republish # Revert and republish in one step

	## Pre-flight Checks
	"""
end
