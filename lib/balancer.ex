defmodule ClusterEx.Balancer do

  def balance_clusters(clusters, opts), do: balance_clusters(clusters, 20, opts)
  def balance_clusters(clusters, 0, _), do: clusters
  def balance_clusters(clusters, iteration, opts) do
    max_vacancy = opts[:max_vacancy]
    soft_limit = opts[:soft_limit]
    max_overload = opts[:max_overload]

    centroids = Map.keys(clusters)
    vacancies = find_vacant_clusters(clusters, soft_limit, max_vacancy)
    overloads = find_overloaded_clusters(clusters, soft_limit, max_overload)
    points = balance_final(clusters, vacancies, overloads)
    |> Enum.map(fn {_, points} -> points end)
    |> List.flatten

    new_clusters = Kmeans.clusters(centroids, points)
    balance_clusters(new_clusters, iteration - 1, opts)
  end

  def balance_final(clusters, vacancies, overloads) do
    vacant_centroids = Enum.map(vacancies, fn {{c, _}, _} -> c end)
    overloaded_centroids = Enum.map(overloads, fn {{c, _}, _} -> c end)

    transfer_vacancies = clusters
    |> get_distance_data(vacant_centroids, overloaded_centroids)
    |> get_transfer_vacancies(vacancies, vacant_centroids)

    transfer_points = Enum.map(transfer_vacancies, fn {_, p} -> p end)

    update_clusters(clusters, transfer_points, vacant_centroids, transfer_vacancies)
  end

  defp update_clusters(clusters, transfer_points, vacant_centroids, transfer_vacancies) do
    Enum.map(clusters, fn {c, p} ->
      {c, case Enum.any?(vacant_centroids, &(&1 == c)) do
        true ->
          {_, points} = Enum.find(transfer_vacancies, fn {vc, _} -> vc == c end)
          points ++ p
        false ->  p -- transfer_points
      end}
    end)
  end

  defp get_distance_data(clusters, vacant_centroids, overloaded_centroids) do
    overloaded_centroids
    |> Enum.map(fn c ->
          points = clusters[c]
          Enum.map(points, fn {_, p} = point ->
            {point, Enum.map(vacant_centroids, fn vc ->
              {vc, Kmeans.distance(vc, p)}
            end)}
          end)
        end)
    |> List.flatten
  end

  defp get_transfer_vacancies(distance_data, vacancies, vacant_centroids) do
    vacant_centroids
    |> Enum.map(fn c ->
        {_, transfers} = Enum.find(vacancies, fn {{vc, _}, _} -> vc == c end)
        transfers = transfers/2
        {c, distance_data
        |> Enum.map(fn {p, d} ->
            {p, Enum.find(d, fn {vc, _} -> vc == c end)}
          end)
        |> Enum.sort_by(fn {_, {_, d}} -> d end)
        |> Enum.map(fn {p1, _} -> p1 end)
        |> Enum.take(transfers)}
      end)
  end

  defp find_vacant_clusters(clusters, soft_limit, max_vacancy) do
    clusters
    |> Enum.map(fn {centroid, points} ->
      l = length(points)
      e = soft_limit - max_vacancy - l
      cond do
        e > 0 -> {{centroid, points}, e}
        true -> nil
      end
    end)
    |> Enum.filter(&(&1))
  end

  defp find_overloaded_clusters(clusters, soft_limit, max_overload) do
    clusters
    |> Enum.map(fn {centroid, points} ->
      l = length(points)
      e = l - (soft_limit + max_overload)
      cond do
        e > 0 -> {{centroid, points}, e}
        true -> nil
      end
    end)
    |> Enum.filter(&(&1))
  end

end