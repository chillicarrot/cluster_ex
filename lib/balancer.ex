defmodule ClusterEx.Balancer do
  @max_extra_points 5
  @soft_limit 25

  def balance_clusters(clusters, 0), do: clusters
  def balance_clusters(clusters, limit \\ 20) do
    vacancies = find_vacant_clusters(clusters)
    overloads = find_overloaded_clusters(clusters)
    new_clusters = balance(clusters, vacancies, overloads)
    balance_clusters(new_clusters, limit - 1)
  end

  defp balance(clusters, [], _), do: clusters
  defp balance(clusters, _, []), do: clusters
  defp balance(clusters, [{{vc, vcp}, vacant} | vrest], [{{ec, ecp}, extra} | erest]) do
    diff = vacant - extra
    transfers = ((diff > 0) && extra) || vacant

    transfer_points = ecp
    |> sort(vc)
    |> Enum.take(transfers)


    vcp = vcp ++ transfer_points
    ecp = ecp -- transfer_points

    overloads = case transfers < extra do
      true -> [{{ec, ecp}, extra - transfers} | erest]
      _ -> erest
    end

    vacancies = case transfers < vacant do
      true -> [{{vc, vcp}, vacant - transfers} | vrest]
      _ -> vrest
    end

    new_clusters = clusters
    |> put_in([vc], vcp)
    |> put_in([ec], ecp)
    balance(new_clusters, vacancies, overloads)
  end

  defp sort(points, centroid) do
    points
    |> Enum.sort_by(fn {_, point} -> Kmeans.distance(centroid, point) end)
  end


  defp find_vacant_clusters(clusters) do
    clusters
    |> Enum.map(fn {centroid, points} ->
      l = length(points)
      e = @soft_limit + @max_extra_points - l
      cond do
        e > 0 -> {{centroid, points}, e}
        true -> nil
      end
    end)
    |> Enum.filter(&(&1))
  end

  defp find_overloaded_clusters(clusters) do
    clusters
    |> Enum.map(fn {centroid, points} ->
      l = length(points)
      e = l - (@soft_limit + @max_extra_points)
      cond do
        e > 0 -> {{centroid, points}, e}
        true -> nil
      end
    end)
    |> Enum.filter(&(&1))
  end

end