defmodule ClusterEx do
  alias ClusterEx.Balancer

  def cluster(points, opts) do
    points
    |> Kmeans.run(opts[:clusters], 10)
    |> Balancer.balance_clusters(opts)
  end

  def raw_data(clusters) do
    Enum.map(clusters, fn {_, cluster} ->
      Enum.map(cluster, fn {_tag, {p1, p2}} -> [p1, p2]  end)
    end)
  end
end
