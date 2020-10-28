# mix credo explain

`explain` allows you to dig deeper into an issue, by showing you details about the issue and the reasoning by it being reported. To be convenient, you can just copy-paste the `filename:line_number:column` string from the report behind the Credo command to check it out.

*Credits:* This is inspired by how you can snap the info from failed tests behind `mix test`.

Example usage:

    $ mix credo lib/my_app/server.ex:10:24          # show explanation for the issue
    $ mix credo explain lib/my_app/server.ex:10:24  # same thing

There are no additional options.
