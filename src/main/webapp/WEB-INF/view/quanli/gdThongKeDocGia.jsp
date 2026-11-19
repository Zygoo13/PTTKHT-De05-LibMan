<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Thống kê độc giả"/>
<c:set var="catalogView" value="${true}"/>
<c:set var="pageStylesheet" value="/assets/css/gdThongKeDocGia.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<p class="search-hint" id="report-hint">Chọn khoảng thời gian theo ngày mượn để thống kê số lần mượn của từng độc giả.</p>
<section class="results-panel report-results" aria-label="Báo cáo lượt mượn">
    <form class="report-form" action="<c:url value='/reports/readers'/>" method="get" aria-label="Kỳ thống kê">
        <label class="field" for="startDate">
            Từ ngày
            <input type="date" id="startDate" name="startDate" required
                   value="<c:out value="${startDate}"/>">
        </label>
        <label class="field" for="endDate">
            Đến ngày
            <input type="date" id="endDate" name="endDate" required
                   value="<c:out value="${endDate}"/>">
        </label>
        <button type="submit">Xem thống kê</button>
    </form>
    <c:if test="${not empty error}"><p class="notice error" role="alert"><c:out value="${error}"/></p></c:if>
    <c:choose>
        <c:when test="${not empty statistics}">
            <header class="results-header">
                <h2>Lượt mượn theo độc giả</h2>
                <span>${statistics.size()} độc giả có lượt mượn</span>
            </header>
            <div class="table-scroll" tabindex="0" role="region" aria-label="Thống kê độc giả">
                <table>
                    <thead>
                        <tr>
                            <th scope="col">Mã độc giả</th>
                            <th scope="col">Họ và tên</th>
                            <th scope="col" class="number-column">Số lần mượn</th>
                            <th scope="col">Chi tiết</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="reader" items="${statistics}">
                            <c:url var="loansUrl" value="/reports/readers/loans">
                                <c:param name="startDate" value="${startDate}"/>
                                <c:param name="endDate" value="${endDate}"/>
                                <c:param name="readerId" value="${reader.id}"/>
                            </c:url>
                            <tr>
                                <td class="code"><c:out value="${reader.readerCode}"/></td>
                                <td><strong><c:out value="${reader.fullName}"/></strong></td>
                                <td class="number number-column"><c:out value="${reader.borrowCount}"/></td>
                                <td>
                                    <a class="action"
                                       href="<c:out value="${loansUrl}"/>"
                                       aria-label="Xem các lần mượn của <c:out value="${reader.fullName}"/>">
                                        Xem các lần mượn
                                    </a>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:when test="${statistics ne null}"><p class="report-empty">Kỳ này không có lượt mượn.</p></c:when>
    </c:choose>
</section>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
