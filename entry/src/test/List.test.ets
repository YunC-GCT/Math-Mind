import localUnitTest from './LocalUnit.test';
import markdownRendererProtocolTest from './MarkdownRendererProtocol.test';

export default function testsuite() {
  localUnitTest();
  markdownRendererProtocolTest();
}
