prefix = Triplex.to_prefix(tenant)
repo.insert!(%Triplex.Note{body: "seeded note for #{tenant}"}, prefix: prefix)
