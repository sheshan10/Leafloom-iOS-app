import { Heart, LayoutGrid, List, MapPin, Plus, SlidersHorizontal, X } from 'lucide-react';
import { useCallback, useDeferredValue, useMemo, useState } from 'react';
import { useRouter } from '../../app/router';
import { IconButton, PrimaryButton, SecondaryButton } from '../../components/Button';
import { CategoryIcon } from '../../components/Icons';
import { TabScreen } from '../../components/Layout';
import { PlantCard, PlantRow } from '../../components/PlantCard';
import { FilterChip, SearchBar } from '../../components/SearchBar';
import { EmptyState } from '../../components/States';
import { useToast } from '../../components/Toast';
import { plantCategories } from '../../data/catalog';
import { useData } from '../../data/store';
import type { PlantCategory } from '../../types/models';
import { applyPlantQuery, distinctLocations, emptyQuery, isQueryActive, nextCareIndex, type PlantQuery, type PlantSort } from '../../utils/filters';
import { useSessionState } from '../../utils/sessionState';

const sorts: { id: PlantSort; label: string }[] = [
  { id: 'recent', label: 'Recently added' },
  { id: 'alphabetical', label: 'A–Z' },
  { id: 'nextCare', label: 'Next care' },
];

export function CollectionScreen() {
  const { plants, tasks, preferences, actions } = useData();
  const router = useRouter();
  const toast = useToast();
  const [query, setQuery] = useSessionState<PlantQuery>('collection.query', emptyQuery);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const deferredSearch = useDeferredValue(query.search);
  const layout = preferences.collectionLayout;

  // Indexes are rebuilt only when the underlying records change, not on every keystroke.
  const nextCare = useMemo(() => nextCareIndex(tasks), [tasks]);
  const locations = useMemo(() => distinctLocations(plants), [plants]);
  const results = useMemo(
    () => applyPlantQuery(plants, { ...query, search: deferredSearch }, nextCare),
    [plants, query, deferredSearch, nextCare],
  );
  const active = isQueryActive(query);
  const filterCount = query.categories.length + (query.location ? 1 : 0) + (query.favoritesOnly ? 1 : 0);

  const toggleCategory = (c: PlantCategory) =>
    setQuery((q) => ({ ...q, categories: q.categories.includes(c) ? q.categories.filter((x) => x !== c) : [...q.categories, c] }));

  const onFavorite = useCallback(
    async (id: string) => {
      try {
        const on = await actions.toggleFavorite(id);
        toast(on ? 'Added to favourites' : 'Removed from favourites', { kind: 'info', durationMs: 1800 });
      } catch (e) {
        toast(e instanceof Error ? e.message : 'Could not update favourite.', { kind: 'error' });
      }
    },
    [actions, toast],
  );

  return (
    <TabScreen
      title="My Plants"
      subtitle={`${plants.length} plant${plants.length === 1 ? '' : 's'}`}
      trailing={
        <>
          <IconButton
            icon={layout === 'grid' ? List : LayoutGrid}
            label={layout === 'grid' ? 'Show as list' : 'Show as grid'}
            onClick={() => void actions.updatePreferences({ collectionLayout: layout === 'grid' ? 'list' : 'grid' })}
          />
          <IconButton icon={Plus} label="Add plant" tone="filled" onClick={() => router.openSheet({ name: 'addPlant' })} />
        </>
      }
    >
      <div className="collection-controls">
        <div className="collection-controls__row">
          <SearchBar value={query.search} onChange={(search) => setQuery((q) => ({ ...q, search }))} placeholder="Search name, species or tag" />
          <button
            type="button"
            className={`filter-toggle ${filtersOpen ? 'is-open' : ''} ${filterCount ? 'has-filters' : ''}`}
            aria-expanded={filtersOpen}
            aria-controls="collection-filters"
            onClick={() => setFiltersOpen((o) => !o)}
          >
            <SlidersHorizontal size={18} aria-hidden />
            <span className="visually-hidden">Filters</span>
            {filterCount > 0 && <span className="filter-toggle__count">{filterCount}</span>}
          </button>
        </div>

        <div className="chip-row" role="group" aria-label="Sort by">
          {sorts.map((s) => (
            <FilterChip key={s.id} label={s.label} selected={query.sort === s.id} onToggle={() => setQuery((q) => ({ ...q, sort: s.id }))} />
          ))}
          <FilterChip
            label="Favourites"
            icon={<Heart size={14} aria-hidden fill={query.favoritesOnly ? 'currentColor' : 'none'} />}
            selected={query.favoritesOnly}
            onToggle={() => setQuery((q) => ({ ...q, favoritesOnly: !q.favoritesOnly }))}
          />
        </div>

        <div id="collection-filters" className={`filter-panel ${filtersOpen ? 'is-open' : ''}`} hidden={!filtersOpen}>
          <p className="t-eyebrow">Category</p>
          <div className="chip-row chip-row--wrap">
            {plantCategories.map((c) => (
              <FilterChip key={c.id} label={c.label} icon={<CategoryIcon category={c.id} size={14} />} selected={query.categories.includes(c.id)} onToggle={() => toggleCategory(c.id)} />
            ))}
          </div>
          {locations.length > 0 && (
            <>
              <p className="t-eyebrow">Location</p>
              <div className="chip-row chip-row--wrap">
                {locations.map((l) => (
                  <FilterChip key={l} label={l} icon={<MapPin size={13} aria-hidden />} selected={query.location === l} onToggle={() => setQuery((q) => ({ ...q, location: q.location === l ? undefined : l }))} />
                ))}
              </div>
            </>
          )}
        </div>

        {active && (
          <div className="results-bar" role="status">
            <span>
              {results.length} of {plants.length} plants
            </span>
            <button type="button" className="text-btn" onClick={() => setQuery({ ...emptyQuery, sort: query.sort })}>
              <X size={14} aria-hidden /> Clear filters
            </button>
          </div>
        )}
      </div>

      {plants.length === 0 ? (
        <EmptyState
          illustration="plants"
          title="No plants yet"
          message="Add a plant you already know, or use Identify to get a suggestion from a photo."
          action={
            <PrimaryButton icon={Plus} onClick={() => router.openSheet({ name: 'addPlant' })}>
              Add your first plant
            </PrimaryButton>
          }
        />
      ) : results.length === 0 ? (
        <EmptyState
          illustration="search"
          title="No matching plants"
          message={query.search ? `Nothing matches “${query.search}” with the current filters.` : 'No plants match these filters.'}
          action={
            <SecondaryButton icon={X} onClick={() => setQuery({ ...emptyQuery, sort: query.sort })}>
              Clear search and filters
            </SecondaryButton>
          }
        />
      ) : layout === 'grid' ? (
        <div className="plant-grid" aria-label="Plants">
          {results.map((p) => (
            <PlantCard key={p.id} plant={p} nextCare={nextCare.get(p.id)} onOpen={() => router.push({ name: 'plantDetails', plantId: p.id })} onToggleFavorite={() => void onFavorite(p.id)} />
          ))}
        </div>
      ) : (
        <div className="list-card" aria-label="Plants">
          {results.map((p) => (
            <PlantRow key={p.id} plant={p} nextCare={nextCare.get(p.id)} onOpen={() => router.push({ name: 'plantDetails', plantId: p.id })} onToggleFavorite={() => void onFavorite(p.id)} />
          ))}
        </div>
      )}
    </TabScreen>
  );
}
