/**
 * List.test.ets — agents 模块本地单元测试入口
 *
 * 每个参与单元测试的模块都需要一个 src/test/ 目录。
 * 本文件导入 KnowledgeModelMVP 的测试套件。
 */

import knowledgeModelTest from './KnowledgeModelMVP.test';

export default function testsuite() {
  knowledgeModelTest();
}
