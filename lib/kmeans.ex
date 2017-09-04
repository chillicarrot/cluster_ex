defmodule Kmeans do

  defp sq(x) do
    x * x
  end

  def distance({x1, y1}, {x2, y2}) do
    :math.sqrt(sq(x1 - x2) + sq(y1 - y2))
  end

  def closest({_, {x, y}}, centroids) do
    Enum.min_by(centroids, &(distance(&1, {x, y})))
  end

  def clusters(centroids, points) do
    points
    |> Enum.group_by(&closest(&1, centroids))
  end

  defp sum({x1, y1}, {x2, y2}) do
    {x1 + x2, y1 + y2}
  end

  defp shrink({x, y}, factor) do
    {x / factor, y / factor}
  end

  defp average({_, cluster}) do
    cluster
    |> Enum.reduce({0, 0}, fn({_, p1}, current) -> sum(p1, current) end)
    |> shrink(length(cluster))
  end

  defp step(points, iterations, centroids) do
    case iterations do
      0 -> centroids
      _ -> centroids = centroids
        |> clusters(points)
        |> Enum.map(&average/1)
        step(points, iterations - 1, centroids)
    end
  end

  def run(points, k, iterations) do
    centroids = points
    |> Enum.take(k)
    |> Enum.map(fn {_, p} -> p end)

    points
    |> step(iterations, centroids)
    |> clusters(points)
  end

end