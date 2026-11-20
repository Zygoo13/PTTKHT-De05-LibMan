<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Các lần mượn"/>
<c:set var="catalogView" value="${true}"/>
<c:set var="pageStylesheet" value="/assets/css/gdLuotMuonDocGia.css?v=2"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<c:url var="reportUrl" value="/reports/readers">
    <c:param name="startDate" value="${startDate}"/>
    <c:param name="endDate" value="${endDate}"/>
</c:url>
<a class="back" href="<c:out value="${reportUrl}"/>">← Quay về thống kê độc giả</a>
<div class="report-title">
    <h2 class="module-subtitle">Các lần mượn của <c:out value="${reader.fullName}"/></h2>
    <span class="report-code">Mã độc giả <strong><c:out value="${reader.readerCode}"/></strong></span>
</div>
<p class="summary">Kỳ thống kê <strong><c:out value="${periodLabel}"/></strong></p>
<section class="results-panel report-results" aria-labelledby="loan-results-heading">
    <header class="results-header">
        <h2 id="loan-results-heading">Danh sách lần mượn</h2>
        <span>${loans.size()} lần mượn</span>
    </header>
    <div class="table-scroll" tabindex="0" role="region" aria-label="Các lần mượn">
        <table>
            <thead>
                <tr>
                    <th scope="col">Mã phiếu</th>
                    <th scope="col">Ngày giờ mượn</th>
                    <th scope="col" class="number-column">Số bản</th>
                    <th scope="col">Chi tiết</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="loan" items="${loans}">
                    <c:set var="totalCount" value="${loan.loanDetails.size()}"/>
                    <c:url var="detailUrl" value="/reports/readers/loans/detail">
                        <c:param name="startDate" value="${startDate}"/>
                        <c:param name="endDate" value="${endDate}"/>
                        <c:param name="readerId" value="${readerId}"/>
                        <c:param name="loanId" value="${loan.id}"/>
                    </c:url>
                    <tr>
                        <td class="code"><c:out value="${loan.loanNumber}"/></td>
                        <td><c:out value="${checkoutLabels[loan.id]}"/></td>
                        <td class="number-column"><c:out value="${totalCount}"/></td>
                        <td>
                            <c:if test="${totalCount gt 0}">
                                <a class="action"
                                   href="<c:out value="${detailUrl}"/>"
                                   aria-label="Xem chi tiết <c:out value="${loan.loanNumber}"/>">
                                    Xem chi tiết
                                </a>
                            </c:if>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</section>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
