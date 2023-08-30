defmodule ExNVRWeb.RecordingListLive do
  @moduledoc false

  use ExNVRWeb, :live_view

  alias ExNVRWeb.Router.Helpers, as: Routes
  alias ExNVR.Recordings

  def render(assigns) do
    ~H"""
    <div class="grow">
      <.table id="recordings" rows={@recordings}>
        <:col :let={recording} label="Id"><%= recording.id %></:col>
        <:col :let={recording} label="Device"><%= recording.device.name %></:col>
        <:col :let={recording} label="Start-date">
          <%= format_date(recording.start_date, recording.device.timezone) %>
        </:col>
        <:col :let={recording} label="End-date">
          <%= format_date(recording.end_date, recording.device.timezone) %>
        </:col>
        <:action :let={recording}>
          <.link
            href={~p"/api/devices/#{recording.device_id}/recordings/#{recording.filename}/blob"}
            class="inline-flex items-center text-gray-900 rounded-lg"
            id={"recording-#{recording.id}-link"}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="currentColor"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="white"
              class="w-6 h-6"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
              />
            </svg>
          </.link>
        </:action>
      </.table>
      <nav aria-label="Page navigation" class="flex justify-end mt-4">
        <ul class="flex items-center -space-x-px h-8 text-sm">
          <li>
            <a
              href="#"
              phx-click="nav"
              phx-value-page={@page_number - 1}
              class={["flex items-center justify-center px-3 h-8 ml-0 leading-tight bg-white border border-gray-300 rounded-l-lg"] ++
                if @page_number <= 1,
                  do:
                    ["pointer-events-none text-gray-300"],
                  else:
                    ["text-gray-500 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"]
              }
            >
              <span class="sr-only">Previous</span>
              <svg
                class="w-2.5 h-2.5"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 6 10"
              >
                <path
                  stroke="currentColor"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 1 1 5l4 4"
                />
              </svg>
            </a>
          </li>
          <%= if @total_pages > 6 do %>
            <%= for page <- [1,2] do %>
              <li>
                <a
                  href="#"
                  phx-click="nav"
                  phx-value-page={page}
                  class={["flex items-center justify-center px-3 h-8 leading-tight border dark:border-gray-700"] ++
                    if @page_number == page,
                      do:
                        ["z-10 pointer-events-none text-blue-600 bg-blue-50 border-blue-300 hover:bg-blue-100 hover:text-blue-700 dark:bg-gray-700 dark:text-white"],
                      else:
                        ["text-gray-500 bg-white border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"]
                  }
                >
                <%= page %>
                </a>
              </li>
            <% end %>
            <%= if @page_number > 4 do %>
              <li>
                <span class="flex items-center justify-center px-3 h-8 leading-tight text-gray-500">
                  ...
                </span>
              </li>
            <% end %>
            <%= for idx <-  Enum.to_list(3..@total_pages-2) do %>
              <%= if abs(@page_number - idx) <= 1 do %>
                <li>
                  <a
                    href="#"
                    phx-click="nav"
                    phx-value-page={idx}
                    class={["flex items-center justify-center px-3 h-8 leading-tight border dark:border-gray-700"] ++
                      if @page_number == idx,
                        do:
                          ["z-10 pointer-events-none text-blue-600 bg-blue-50 border-blue-300 hover:bg-blue-100 hover:text-blue-700 dark:bg-gray-700 dark:text-white"],
                        else:
                          ["text-gray-500 bg-white border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"]
                    }
                  >
                    <%= idx %>
                  </a>
                </li>
              <% end %>
            <% end %>
            <%= if @page_number < @total_pages - 3 do %>
              <li>
                <span class="flex items-center justify-center px-3 h-8 leading-tight text-gray-500">
                  ...
                </span>
              </li>
            <% end %>
            <%= for page <- [@total_pages-1, @total_pages] do %>
              <li>
                <a
                  href="#"
                  phx-click="nav"
                  phx-value-page={page}
                  class={["flex items-center justify-center px-3 h-8 leading-tight border dark:border-gray-700"] ++
                    if @page_number == page,
                      do:
                        ["z-10 pointer-events-none text-blue-600 bg-blue-50 border-blue-300 hover:bg-blue-100 hover:text-blue-700 dark:bg-gray-700 dark:text-white"],
                      else:
                        ["text-gray-500 bg-white border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"]
                  }
                >
                <%= page %>
                </a>
              </li>
            <% end %>
          <% else %>
          <%= for idx <-  Enum.to_list(1..@total_pages) do %>
              <li>
                <a
                  href="#"
                  phx-click="nav"
                  phx-value-page={idx}
                  class={["flex items-center justify-center px-3 h-8 leading-tight border dark:border-gray-700"] ++
                    if @page_number == idx,
                      do:
                        ["z-10 pointer-events-none text-blue-600 bg-blue-50 border-blue-300 hover:bg-blue-100 hover:text-blue-700 dark:bg-gray-700 dark:text-white"],
                      else:
                        ["text-gray-500 bg-white border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"]
                  }
                >
                  <%= idx %>
                </a>
              </li>
            <% end %>
          <% end %>
          <li>
            <a
              href="#"
              phx-click="nav"
              phx-value-page={@page_number + 1}
              class={["flex items-center justify-center px-3 h-8 leading-tight border border-gray-300 bg-white rounded-r-lg"] ++
                if @page_number >= @total_pages,
                  do:
                    ["pointer-events-none text-gray-300"],
                  else:
                    ["text-gray-500 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"]
              }
            >
              <span class="sr-only">Next</span>
              <svg
                class="w-2.5 h-2.5"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 6 10"
              >
                <path
                  stroke="currentColor"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="m1 9 4-4-4-4"
                />
              </svg>
            </a>
          </li>
        </ul>
      </nav>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, assign(socket, %{})}
  end

  def handle_event("nav", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: Routes.recording_list_path(socket, :list, page: page))}
  end

  def handle_params(%{"page" => page}, _uri, socket) do
    assigns = get_and_assign_page(page)
    {:noreply, assign(socket, assigns)}
  end

  def handle_params(_params, _uri, socket) do
    assigns = get_and_assign_page(nil)
    {:noreply, assign(socket, assigns)}
  end

  defp get_and_assign_page(page_number) do
    %{
      entries: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } = Recordings.paginate_recordings(page: page_number)

    [
      recordings: entries,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages,
      form: nil
    ]
  end

  defp format_date(date, timezone) do
    date
    |> DateTime.shift_zone!(timezone)
    |> Calendar.strftime("%b %d, %Y %H:%M:%S")
  end
end