import { Card, PushedScreen, SectionHeader } from '../../components/Layout';
import { BrandMark } from '../../components/Icons';
import { APP_VERSION } from './SettingsScreen';

const tech = [
  ['SwiftUI', 'Interface, navigation (NavigationStack), animation'],
  ['Core Data', 'Plants, care tasks, journal and identification history'],
  ['Core ML + Vision', 'On-device plant image classification'],
  ['PhotosUI', 'Photo library picker'],
  ['UserNotifications', 'Local care reminders'],
  ['Swift Charts', 'Insights'],
];

export function AboutScreen() {
  return (
    <PushedScreen title="About">
      <div className="about-hero">
        <BrandMark size={72} />
        <h1 className="t-title">LeafLoom</h1>
        <p className="t-subhead t-secondary">AI Plant Care & Smart Gardening</p>
        <p className="t-footnote t-secondary">Version {APP_VERSION}</p>
      </div>
      <Card>
        <p className="t-body">
          LeafLoom helps indoor plant owners and beginner gardeners keep track of their plants, identify unfamiliar ones, remember care and see growth over time — privately, on their own device.
        </p>
      </Card>
      <SectionHeader title="Built with" />
      <Card>
        <dl className="tech-list">
          {tech.map(([k, v]) => (
            <div key={k}>
              <dt>{k}</dt>
              <dd>{v}</dd>
            </div>
          ))}
        </dl>
      </Card>
      <SectionHeader title="Credits" />
      <Card>
        <p className="t-footnote t-secondary">
          Illustrations, brand mark and category icons are original LeafLoom artwork. Sample plant photographs are AI-generated for this project. Interface icons: Lucide (ISC licence). Full details in docs/ASSET_ATTRIBUTION.md.
        </p>
      </Card>
      <p className="t-footnote t-secondary disclaimer">SE4041 Mobile Application Design and Development — Assignment 02.</p>
    </PushedScreen>
  );
}
