defmodule Ueberauth.Strategy.Mailchimp do
  @moduledoc """
  Implements an ÜeberauthMailchimp strategy for authentication with mailchimp.com.

  When configuring the strategy in the Üeberauth providers, you can specify some defaults.

  config :ueberauth, Ueberauth,
    providers: [
      mailchimp: { Ueberauth.Strategy.Mailchimp, [] }
    ]
  ```
  """
  use Ueberauth.Strategy,
    uid_field: :email,
    oauth2_module: Ueberauth.Strategy.Mailchimp.OAuth

  alias Ueberauth.Auth.Credentials

  # When handling the request just redirect to Mailchimp
  @doc false
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    team = option(conn, :team)
    opts = if team, do: Keyword.put(opts, :team, team), else: opts

    callback_url = callback_url(conn)

    callback_url =
      if String.ends_with?(callback_url, "?"),
        do: String.slice(callback_url, 0..-2),
        else: callback_url

    opts = Keyword.put(opts, :redirect_uri, callback_url)
    module = option(conn, :oauth2_module)

    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  # When handling the callback, if there was no errors we need to
  # make two calls. The first, to fetch the mailchimp auth is so that we can get hold of
  # the user id so we can make a query to fetch the user info.
  # So that it is available later to build the auth struct, we put it in the private section of the conn.
  @doc false
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    params = [code: code]
    redirect_uri = get_redirect_uri(conn)

    options = %{
      options: [
        client_options: [redirect_uri: redirect_uri]
      ]
    }

    token = apply(module, :get_token!, [params, options])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      conn
      |> store_token(token)
    end
  end

  # If we don't match code, then we have an issue
  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  # We store the token for use later when fetching the mailchimp auth and user and constructing the auth struct.
  @doc false
  defp store_token(conn, token) do
    put_private(conn, :mailchimp_token, token)
  end

  # Remove the temporary storage in the conn for our data. Run after the auth struct has been built.
  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:mailchimp_token, nil)
  end


  @doc false
  def credentials(conn) do
    token = conn.private.mailchimp_token
    auth = conn.private[:mailchimp_auth]
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, ",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes,
      other: %{}
    }
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp get_redirect_uri(%Plug.Conn{} = conn) do
    config = Application.get_env(:ueberauth, Ueberauth)
    redirect_uri = Keyword.get(config, :redirect_uri)

    if is_nil(redirect_uri) do
      callback_url(conn)
    else
      redirect_uri
    end
  end
end
