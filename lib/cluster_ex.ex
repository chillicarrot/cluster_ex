defmodule ClusterEx do
  alias ClusterEx.Balancer

  def cluster(points, clusters \\ 3) do
    points
    |> Kmeans.run(clusters, 10)
    |> Balancer.balance_clusters
  end

  def raw_data(clusters) do
    Enum.map(clusters, fn {_, cluster} ->
      Enum.map(cluster, fn {_tag, {p1, p2}} -> [p1, p2]  end)
    end)
  end
end
