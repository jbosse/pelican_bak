defmodule Pelican.CountriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pelican.Countries` context.
  """

  @doc """
  Generate a country.
  """
  def country_fixture(attrs \\ %{}) do
    {:ok, country} =
      attrs
      |> Enum.into(%{
        code: "some code",
        flag: "some flag",
        name: "some name",
        notification_offset: 42
      })
      |> Pelican.Countries.create_country()

    country
  end
end
