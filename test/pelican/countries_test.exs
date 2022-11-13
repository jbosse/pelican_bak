defmodule Pelican.CountriesTest do
  use Pelican.DataCase

  alias Pelican.Countries

  describe "countries" do
    alias Pelican.Countries.Country

    import Pelican.CountriesFixtures

    @invalid_attrs %{code: nil, flag: nil, name: nil, notification_offset: nil}

    test "list_countries/0 returns all countries" do
      country = country_fixture()
      assert Countries.list_countries() == [country]
    end

    test "get_country!/1 returns the country with given id" do
      country = country_fixture()
      assert Countries.get_country!(country.id) == country
    end

    test "create_country/1 with valid data creates a country" do
      valid_attrs = %{code: "some code", flag: "some flag", name: "some name", notification_offset: 42}

      assert {:ok, %Country{} = country} = Countries.create_country(valid_attrs)
      assert country.code == "some code"
      assert country.flag == "some flag"
      assert country.name == "some name"
      assert country.notification_offset == 42
    end

    test "create_country/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Countries.create_country(@invalid_attrs)
    end

    test "update_country/2 with valid data updates the country" do
      country = country_fixture()
      update_attrs = %{code: "some updated code", flag: "some updated flag", name: "some updated name", notification_offset: 43}

      assert {:ok, %Country{} = country} = Countries.update_country(country, update_attrs)
      assert country.code == "some updated code"
      assert country.flag == "some updated flag"
      assert country.name == "some updated name"
      assert country.notification_offset == 43
    end

    test "update_country/2 with invalid data returns error changeset" do
      country = country_fixture()
      assert {:error, %Ecto.Changeset{}} = Countries.update_country(country, @invalid_attrs)
      assert country == Countries.get_country!(country.id)
    end

    test "delete_country/1 deletes the country" do
      country = country_fixture()
      assert {:ok, %Country{}} = Countries.delete_country(country)
      assert_raise Ecto.NoResultsError, fn -> Countries.get_country!(country.id) end
    end

    test "change_country/1 returns a country changeset" do
      country = country_fixture()
      assert %Ecto.Changeset{} = Countries.change_country(country)
    end
  end
end
