defmodule LanguageWeb.ReadController do
  use LanguageWeb, :controller

  alias Language.{ExternalSite, TextModifier}

  def browse(conn, %{"site" => site}) do
    case ExternalSite.make_request(conn, site) do
      {:ok, content} ->
        user = Guardian.Plug.current_resource(conn)

        {:ok, head, body} =
          ExternalSite.update_site(site, content, %{
            update_visible_links: &create_local_link/1,
            update_visible_text: TextModifier.get_update_function(user.id)
          })

        render(
          conn,
          "index.html",
          head: head,
          body: body,
          layout: {LanguageWeb.ReadView, "index.html"}
        )

      {:error, message} ->
        put_flash(conn, :error, message)
        |> redirect(to: read_path(conn, :start))
    end
  end

  def browse(conn, _params) do
    redirect(conn, to: read_path(conn, :start))
  end

  def start(conn, _params) do
    render(conn, "start.html")
  end

  defp create_local_link(url) do
    read_path(LanguageWeb.Endpoint, :browse, site: url)
  end
end
