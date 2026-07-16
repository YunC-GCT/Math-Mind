function stripPair(raw: string, marker: string): string {
  let result: string = raw
  while (result.indexOf(marker) >= 0) {
    const start: number = result.indexOf(marker)
    const contentStart: number = start + marker.length
    const end: number = result.indexOf(marker, contentStart)
    if (end < 0) {
      break
    }
    result = result.substring(0, start) + result.substring(contentStart, end) + result.substring(end + marker.length)
  }
  return result
}

function stripMarkdownHeading(line: string): string {
  let cursor: number = 0
  while (cursor < line.length && cursor < 3 && line[cursor] === "#") {
    cursor++
  }
  if (cursor > 0 && cursor < line.length && line[cursor] === " ") {
    return line.substring(cursor + 1)
  }
  return line
}

function stripMarkdownHeadings(raw: string): string {
  const lines: string[] = raw.split("\n")
  const cleaned: string[] = []
  for (const line of lines) {
    cleaned.push(stripMarkdownHeading(line))
  }
  return cleaned.join("\n")
}

function cleanLimit(raw: string): string {
  let result: string = raw
  while (result.indexOf("\\lim_{") >= 0) {
    const start: number = result.indexOf("\\lim_{")
    const bodyStart: number = start + 5
    const end: number = result.indexOf("}", bodyStart)
    if (end < 0) {
      break
    }
    const body: string = result.substring(bodyStart, end + 1)
    result = result.substring(0, start) + "lim" + body + result.substring(end + 1)
  }
  return result
}

function cleanFraction(raw: string): string {
  let result: string = raw
  while (result.indexOf("\\frac{") >= 0) {
    const start: number = result.indexOf("\\frac{")
    const numeratorStart: number = start + 6
    const numeratorEnd: number = result.indexOf("}", numeratorStart)
    const denominatorOpen: number = result.indexOf("{", numeratorEnd)
    const denominatorStart: number = denominatorOpen + 1
    const denominatorEnd: number = result.indexOf("}", denominatorStart)
    if (numeratorEnd < 0 || denominatorOpen < 0 || denominatorEnd < 0) {
      break
    }
    const numerator: string = result.substring(numeratorStart, numeratorEnd)
    const denominator: string = result.substring(denominatorStart, denominatorEnd)
    result = result.substring(0, start) + "(" + numerator + ")/(" + denominator + ")" + result.substring(denominatorEnd + 1)
  }
  return result
}

function stripLatexCommands(raw: string): string {
  let result: string = raw
  while (result.indexOf("\\") >= 0) {
    const start: number = result.indexOf("\\")
    let end: number = start + 1
    while (end < result.length && result[end] !== " " && result[end] !== "{" && result[end] !== "\n") {
      end++
    }
    result = result.substring(0, start) + result.substring(end)
  }
  return result
}

export function cleanMarkdown(raw: string): string {
  let result: string = raw
  result = stripPair(result, "**")
  result = stripPair(result, "__")
  result = cleanLimit(result)
  result = result.split("\\to").join("->")
  result = cleanFraction(result)
  result = stripLatexCommands(result)
  result = result.split("{").join("").split("}").join("")
  result = stripMarkdownHeadings(result)
  return result
}
