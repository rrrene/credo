# Releasing a new version

## Checklist

* Ensure `CHANGELOG.md` is up-to-date
* Ensure working dir is clean
* Update version in `mix.exs`
* Create a commit:

      git commit -a -m "Bump version to 0.X.Y"
      git tag -l v0.X.Y
      mix test && mix hex.publish
      git push origin master --tags

* Enjoy!
