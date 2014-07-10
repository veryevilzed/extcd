import LAXer

defmodule Extcd do
  use Application

  @etcd Dict.get(Application.get_all_env(:extcd), :host, "http://localhost:8080/v2/keys/")
  @timeout Dict.get(Application.get_all_env(:extcd), :timeout, 5000)

  defmacrop body_encode(list) do
    quote do
      for {key, value} <- unquote(list), into: "" do
        "#{key}=#{value}&"
      end
    end
  end

  def get(path, options \\ []) do
    case get_with_details(path, options) do
      false -> false
      details -> 
        case la details["node"]["dir"] do
          true -> la details["node"]["nodes"]
          nil -> 
            value = la details["node"]["value"]
            case Jazz.decode(value) do
              {:ok, json} -> json
              _ -> value
            end
        end
    end
  end


  def get_with_details(path, options \\ []) do
    timeout = Keyword.get options, :timeout, @timeout
    case HTTPoison.get "#{@etcd}#{path}", [], [timeout: timeout] do
      %HTTPoison.Response{status_code: 200, body: body} -> body |> Jazz.decode!
      _ -> false
    end
  end

  def set_term(path, value) do
    set(path, value |> :erlang.term_to_binary |> :base64.encode |> URI.encode_www_form)
  end
  
  def get_term(path) do
    case get(path) do
      false -> false
      val -> val |> :base64.decode |> :erlang.binary_to_term
    end
  end

  def set(path, value), do: set(path, value, [])
  def set(path, value, options) when is_binary(value) do
    timeout = Keyword.get options, :timeout, @timeout
    options = Keyword.delete options, :timeout
    case HTTPoison.request :put, "#{@etcd}#{path}", body_encode([value: value] ++ options), [{"Content-Type", "application/x-www-form-urlencoded"}], [timeout: timeout] do
      %HTTPoison.Response{status_code: code, body: body} when code in [200, 201] -> body |> Jazz.decode!
      %HTTPoison.Response{status_code: 307} -> set path, value, options
      _ -> false
    end
     #HTTPoison.request :put, "#{@etcd}#{path}", body_encode([value: value] ++ options), [{"Content-Type", "application/x-www-form-urlencoded"}], [timeout: timeout]
  end
  def set(path, value, options) do
    set(path, Jazz.encode!(value), options)
  end



  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Extcd.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Extcd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
